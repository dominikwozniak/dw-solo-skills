// trigger.ts — Tier 3 of the routing evals: ask the actual router which skill fires.
//
// Tier 2 (routing.ts) is a lexical proxy and free. This one spawns real `claude -p` runs against a
// throwaway fixture repo, reads the first `Skill` tool call out of the stream-json, and reports the
// distribution across trials. It is nondeterministic and it spends subscription quota, so:
//
//   - it NEVER runs in CI and is not in the pre-push gate
//   - it prints the plan and the measured cost, and does nothing at all without --go
//   - it pins the model, because routing is model-dependent and an unpinned answer means nothing
//
// Usage:
//   node evals/trigger.ts                          plan only — what it would run, and nothing else
//   node evals/trigger.ts --go dw-shape dw-grill    run those two skills' first positive
//   node evals/trigger.ts --go --trials 5 dw-git    more trials of one skill
//   node evals/trigger.ts --go --prompt "..."       one ad-hoc prompt, no case file needed
//   node evals/trigger.ts --go --limit 2            two positives per skill instead of one
//
// Erasable TypeScript only — Node strips the types, there is no build step.

import { spawnSync } from "node:child_process"
import {
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from "node:fs"
import { homedir, tmpdir } from "node:os"
import { basename, dirname, join } from "node:path"

const ROOT = dirname(import.meta.dirname)
const CASES_DIR = join(ROOT, "evals", "cases")
const MARKETPLACE = join(ROOT, ".claude-plugin", "marketplace.json")

type Trial = { skill: string | null; costUsd: number; turns: number; ms: number; error?: string }
type Job = { owner: string; prompt: string; trials: Trial[] }

function fail(message: string): never {
  console.error(`trigger.ts: ${message}`)
  process.exit(2)
}

/**
 * Every plugin directory in the marketplace, so all skills load from THIS worktree rather than a
 * subset. The 11 skills span three plugins — dw-doctor lives in dw-solo-setup and dw-handoff in
 * dw-solo-extras — and loading only dw-solo silently removes them from the router's choices, which
 * would make any verdict about a near neighbour meaningless.
 */
function pluginDirs(): string[] {
  if (!existsSync(MARKETPLACE)) fail(`no marketplace manifest at ${MARKETPLACE}`)
  const manifest = JSON.parse(readFileSync(MARKETPLACE, "utf8")) as {
    plugins?: { source?: string }[]
  }
  const dirs: string[] = []
  for (const plugin of manifest.plugins ?? []) {
    const source = (plugin.source ?? "").replace(/^\.\//, "")
    if (source === "") continue
    const path = join(ROOT, source)
    if (existsSync(join(path, "skills"))) dirs.push(path)
  }
  if (dirs.length === 0)
    fail("found no plugin directories with skills/ in the marketplace manifest")
  return dirs
}

/**
 * Every plugin the user has enabled globally, turned off. Without this the cache-installed copy of
 * this very marketplace loads alongside --plugin-dir and each skill appears twice; every unrelated
 * plugin also throws its own skills into the pool the router is choosing from. What the eval wants
 * is this worktree's skills and nothing else.
 */
function suppressGlobalPlugins(): string {
  const path = join(homedir(), ".claude", "settings.json")
  const disabled: Record<string, boolean> = {}
  if (existsSync(path)) {
    try {
      const settings = JSON.parse(readFileSync(path, "utf8")) as {
        enabledPlugins?: Record<string, boolean>
      }
      for (const key of Object.keys(settings.enabledPlugins ?? {})) disabled[key] = false
    } catch {
      // A malformed user settings file is not this tool's problem to fix; the run is just noisier.
      console.warn(`trigger.ts: could not parse ${path} — global plugins may load alongside`)
    }
  }
  return JSON.stringify({ enabledPlugins: disabled })
}

/**
 * The fixture the prompts run against. An empty directory is not representative: several
 * descriptions key off cues a real project has — a `CLAUDE.md`, a git repo, an `.ai/work/` that
 * exists but is empty, meaning "shaped nothing yet".
 */
function makeFixture(): string {
  const dir = mkdtempSync(join(tmpdir(), "dw-trigger-"))
  mkdirSync(join(dir, ".ai", "work"), { recursive: true })
  const git = spawnSync("git", ["-C", dir, "init", "--quiet"], { encoding: "utf8" })
  if (git.status !== 0) fail(`could not git init the fixture at ${dir}`)
  writeFileSync(
    join(dir, "CLAUDE.md"),
    [
      "# demo-service — agent instructions",
      "",
      "A small private Node service. One reader.",
      "",
      "## Commands",
      "",
      "- **Test**: `pnpm test`",
      "- **Lint**: `pnpm lint`",
      "",
      "## Gotchas",
      "",
      "- Nothing yet.",
      "",
    ].join("\n"),
  )
  return dir
}

function loadJobs(filter: string[], limit: number, adhoc: string | null): Job[] {
  if (adhoc !== null) return [{ owner: "(ad-hoc)", prompt: adhoc, trials: [] }]
  if (!existsSync(CASES_DIR)) fail(`no case directory at ${CASES_DIR}`)

  const jobs: Job[] = []
  for (const file of readdirSync(CASES_DIR)
    .filter((f) => f.endsWith(".json"))
    .sort()) {
    const owner = basename(file, ".json")
    if (filter.length > 0 && !filter.includes(owner)) continue
    const parsed = JSON.parse(readFileSync(join(CASES_DIR, file), "utf8")) as {
      positives?: { prompt: string }[]
    }
    for (const positive of (parsed.positives ?? []).slice(0, limit)) {
      jobs.push({ owner, prompt: positive.prompt, trials: [] })
    }
  }

  const missing = filter.filter((name) => !jobs.some((job) => job.owner === name))
  if (missing.length > 0) fail(`no case file for: ${missing.join(", ")}`)
  if (jobs.length === 0) fail("nothing to run — no case files matched")
  return jobs
}

/** The skill name out of a namespaced `plugin:skill` tool input. */
function bareSkill(value: unknown): string | null {
  if (typeof value !== "string" || value === "") return null
  const parts = value.split(":")
  return parts[parts.length - 1]
}

/**
 * Generous enough that a slow opus run never trips it — observed runs finish in 3–7 turns — and
 * finite so a `claude` that hangs on a prompt does not park the whole run forever with no output.
 */
const TRIAL_TIMEOUT_MS = 10 * 60 * 1000

function runTrial(
  prompt: string,
  model: string,
  fixture: string,
  settings: string,
  dirs: string[],
): Trial {
  const args = [
    "-p",
    prompt,
    "--output-format",
    "stream-json",
    "--verbose",
    "--model",
    model,
    "--settings",
    settings,
    // Fine for observing which skill fires; wrong for grading what a skill produces, because the
    // agent narrates instead of acting. This tier only asks "which one".
    "--disallowedTools",
    "Write",
    "Edit",
  ]
  for (const dir of dirs) args.push("--plugin-dir", dir)

  const started = Date.now()
  const run = spawnSync("claude", args, {
    cwd: fixture,
    encoding: "utf8",
    // 'ignore' rather than inherit: `claude -p` waits 3s for piped stdin otherwise.
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 64 * 1024 * 1024,
    timeout: TRIAL_TIMEOUT_MS,
  })
  const ms = Date.now() - started

  if (run.error !== undefined)
    return { skill: null, costUsd: 0, turns: 0, ms, error: String(run.error) }

  let skill: string | null = null
  let costUsd = 0
  let turns = 0
  for (const line of (run.stdout ?? "").split("\n")) {
    if (line.trim() === "") continue
    let event: Record<string, unknown>
    try {
      event = JSON.parse(line) as Record<string, unknown>
    } catch {
      continue
    }
    if (event.type === "assistant" && skill === null) {
      const message = event.message as {
        content?: { type?: string; name?: string; input?: unknown }[]
      }
      for (const block of message?.content ?? []) {
        if (block.type !== "tool_use" || block.name !== "Skill") continue
        const found = bareSkill((block.input as { skill?: unknown })?.skill)
        if (found !== null) {
          skill = found
          break
        }
      }
    }
    if (event.type === "result") {
      costUsd = typeof event.total_cost_usd === "number" ? event.total_cost_usd : 0
      turns = typeof event.num_turns === "number" ? event.num_turns : 0
    }
  }

  const trial: Trial = { skill, costUsd, turns, ms }
  if (run.status !== 0) trial.error = `claude exited ${run.status}`
  return trial
}

function distribution(trials: Trial[]): { label: string; count: number }[] {
  const counts = new Map<string, number>()
  for (const trial of trials) {
    const label = trial.skill ?? "(no skill invoked)"
    counts.set(label, (counts.get(label) ?? 0) + 1)
  }
  return [...counts]
    .map(([label, count]) => ({ label, count }))
    .sort((a, b) => b.count - a.count || a.label.localeCompare(b.label))
}

const USAGE =
  "usage: node evals/trigger.ts [--go] [--trials <n>] [--limit <n>] [--model <name>] [--prompt <text>] [skill...]"

function main(argv: string[]): void {
  let trials = 3
  let limit = 1
  let model = "opus"
  let adhoc: string | null = null
  let go = false
  const filter: string[] = []

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (arg === "--go") go = true
    else if (arg === "--trials") {
      trials = Number(argv[++i])
      if (!Number.isInteger(trials) || trials < 1) fail("--trials needs a positive integer")
    } else if (arg === "--limit") {
      limit = Number(argv[++i])
      if (!Number.isInteger(limit) || limit < 1) fail("--limit needs a positive integer")
    } else if (arg === "--model") {
      model = argv[++i] ?? fail("--model needs a value")
    } else if (arg === "--prompt") {
      adhoc = argv[++i] ?? fail("--prompt needs a value")
    } else if (arg === "-h" || arg === "--help") {
      console.log(USAGE)
      return
    } else if (arg.startsWith("-")) fail(`unknown flag ${arg}\n${USAGE}`)
    else filter.push(arg)
  }

  const jobs = loadJobs(filter, limit, adhoc)
  const runs = jobs.length * trials
  // Resolved once: the manifest cannot change under a run, and re-reading it per trial only
  // buys the chance of a mid-run edit making two trials incomparable.
  const dirs = pluginDirs()

  console.log(
    `plan: ${jobs.length} prompt(s) × ${trials} trial(s) = ${runs} run(s) of \`claude -p\``,
  )
  console.log(`model: ${model} (pinned — routing is model-dependent)`)
  console.log(`plugins: ${dirs.map((d) => basename(d)).join(", ")} from this worktree`)
  for (const job of jobs) console.log(`  ${job.owner.padEnd(10)} "${job.prompt}"`)

  if (!go) {
    console.log(
      `\nThis spends subscription quota and is never run in CI. Add --go to actually run it.`,
    )
    return
  }

  const fixture = makeFixture()
  const settings = suppressGlobalPlugins()
  console.log(`\nfixture: ${fixture}`)

  let spent = 0
  for (const job of jobs) {
    process.stdout.write(`\n▸ ${job.owner}  "${job.prompt}"\n`)
    for (let t = 0; t < trials; t++) {
      const trial = runTrial(job.prompt, model, fixture, settings, dirs)
      job.trials.push(trial)
      spent += trial.costUsd
      const label = trial.skill ?? "(no skill invoked)"
      const flag = trial.error === undefined ? "" : `  [${trial.error}]`
      const hit = trial.skill === job.owner ? "✓" : "✗"
      const seconds = (trial.ms / 1000).toFixed(1)
      console.log(
        `  ${hit} trial ${t + 1}  ${label.padEnd(22)} ${trial.turns} turns  ${seconds}s  $${trial.costUsd.toFixed(4)}${flag}`,
      )
    }
    const dist = distribution(job.trials)
    const summary = dist.map((d) => `${d.label} ${d.count}/${trials}`).join(" · ")
    console.log(`  → ${summary}`)
  }

  console.log("\nverdict:")
  for (const job of jobs) {
    const own = job.trials.filter((trial) => trial.skill === job.owner).length
    const winner = distribution(job.trials)[0]
    const note = own === job.trials.length ? "" : `  ← ${winner.label} took ${winner.count}`
    console.log(`  ${job.owner.padEnd(10)} ${own}/${job.trials.length} to itself${note}`)
  }
  console.log(`\nspent $${spent.toFixed(4)} across ${runs} run(s). Fixture left at ${fixture}`)
}

main(process.argv.slice(2))
