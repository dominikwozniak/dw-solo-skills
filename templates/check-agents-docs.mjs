#!/usr/bin/env node
// Guards the agent-docs contract in a repo scaffolded by dw-init: AGENTS.md is the one always-loaded
// file, it stays inside a budget it declares itself, everything it routes to is real, and the layers
// it routes to do not grow in silence.
//
// Zero dependencies, Node built-ins only — it ships into repos that may have no package.json at all.
// Run it as `node scripts/check-agents-docs.mjs`, or via the `agents:check` script dw-init wires.
//
// Over docs/decisions/ it checks ONE thing, size, and only where a ceiling is declared. A record's
// bar, its sections, its numbering and its supersession stay editorial: a commit blocked because a
// decision record is shaped wrong teaches you to stop writing them. Length is the one failure the
// reader cannot repair by reading more carefully, and it is the same kind of number as the budget
// above — which is why it is measured the same way and declared the same way.
import {
  existsSync,
  lstatSync,
  readFileSync,
  readdirSync,
  readlinkSync,
  realpathSync,
  writeFileSync,
} from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

// The repo root is where `.git` is — a directory in a normal clone, a FILE in a git worktree, so
// existsSync is the right probe for both. The script works at scripts/check-agents-docs.mjs, at the
// root, or anywhere else it gets dropped.
//
// Resolving by "nearest ancestor holding an AGENTS.md" was the obvious version and it was wrong:
// AGENTS.md is a per-directory convention, so a perfectly legal scripts/AGENTS.md ("rules for this
// directory") made this script treat scripts/ as the repo root and grade that file instead — three
// failures about a healthy repo, none of them naming a path you could tell them apart by.
//
// The fallback exists for a copy with no .git above it at all (a tarball, a vendored subtree); there
// the AGENTS.md walk is the best guess available, and the report names the root it settled on either
// way so a wrong one is visible rather than inferred.
const findUp = (marker) => {
  let dir = dirname(fileURLToPath(import.meta.url))
  for (;;) {
    if (existsSync(join(dir, marker))) return dir
    const up = dirname(dir)
    if (up === dir) return null
    dir = up
  }
}

const repoRoot = findUp(".git") ?? findUp("AGENTS.md")
if (repoRoot === null) {
  console.error(
    "agents:check — no .git and no AGENTS.md at or above this script. Nothing to check.",
  )
  process.exit(1)
}
if (!existsSync(join(repoRoot, "AGENTS.md"))) {
  console.error(
    `agents:check — no AGENTS.md at the repo root (${repoRoot}). ` +
      "It is the one file every session loads in full; a topic file under docs/agents/ does not stand in for it.",
  )
  process.exit(1)
}

// One flag, and anything unrecognised is fatal rather than ignored: a typo'd `--update-baselines`
// would otherwise run a plain check, write nothing, and look exactly like success.
const args = process.argv.slice(2)
const update = args.includes("--update-baseline")
for (const arg of args)
  if (arg !== "--update-baseline") {
    console.error(
      `agents:check — unexpected argument ${JSON.stringify(arg)}. Usage: [--update-baseline].`,
    )
    process.exit(2)
  }

const failures = []
const fail = (message) => failures.push(message)
const abs = (path) => join(repoRoot, path)
const read = (path) => readFileSync(abs(path), "utf8")

// Lines as a reader sees them: the final newline TERMINATES the last line rather than starting an
// empty one. A plain `split("\n").length` counted that phantom, so a conventional 40-line file
// measured 41 — a declared ceiling of 40 silently meant 39, and the message named a number no editor
// agreed with.
//
// Deliberately not `wc -l`, which counts newline characters: the two agree on every newline-terminated
// file, which is all of them here, and disagree on the pathological ones in the direction a reader
// would call wrong — `wc -l` says 1 for "a\nb" and 0 for an empty file, where an editor shows 2 and
// 0 and this says 2 and 1. Neither pathology can approach a ceiling, so the readable number wins.
const lineCount = (text) => text.replace(/\n$/, "").split("\n").length

const root = read("AGENTS.md")

// ---------------------------------------------------------------------------
// 1. The budget, read from the file's own prose declaration.
// ---------------------------------------------------------------------------
// One line, one place: `Budget: **120 lines / 10 KB**`. Bare number = bytes, `KB` = ×1024. Anything
// else is malformed and REJECTED rather than guessed at — a budget nobody can parse is a budget
// nobody enforces, and silently reading `10 MB` as 10 bytes would be worse than either.
// Grep-grade on purpose: the declaration has to sit on one line, because that is the only shape a
// reader can check as fast as the script can.
const budgetReport = (() => {
  const line = root.split("\n").find((l) => l.includes("Budget:"))
  if (line === undefined) {
    fail(
      "AGENTS.md declares no budget. Add one to its header prose, e.g. `Budget: **120 lines / 10 KB**`.",
    )
    return null
  }
  const declared = line
    .slice(line.indexOf("Budget:") + "Budget:".length)
    .replaceAll("*", "")
    .replaceAll("`", "")
  const parsed = /^\s*(\d[\d_]*)\s*lines?\s*\/\s*(\d[\d_]*)\s*(kb|b)?\s*(?:[,.;].*)?$/i.exec(
    declared,
  )
  if (parsed === null) {
    fail(
      `AGENTS.md's budget declaration is malformed: "${declared.trim()}". ` +
        "It must read `<N> lines / <M>[ KB]` — a bare number is bytes, KB is ×1024.",
    )
    return null
  }
  const num = (raw) => Number(raw.replaceAll("_", ""))
  const maxLines = num(parsed[1])
  const maxBytes = num(parsed[2]) * (parsed[3]?.toLowerCase() === "kb" ? 1024 : 1)
  const lines = lineCount(root)
  const bytes = Buffer.byteLength(root, "utf8")
  if (lines > maxLines || bytes > maxBytes)
    fail(
      `AGENTS.md is ${lines} lines / ${bytes} B — over its declared ${maxLines}-line / ${maxBytes}-B budget. ` +
        "Move a topic into docs/agents/ and add its Task Router row, rather than trimming a rule.",
    )
  return `AGENTS.md at ${lines}/${maxLines} lines, ${bytes}/${maxBytes} B`
})()

// ---------------------------------------------------------------------------
// 2. No placeholder survived the scaffold.
// ---------------------------------------------------------------------------
// dw-init renders this file from a template. A `{{…}}` token left behind is read as content by the
// next session, and `eval`ed as a command by the lint and typecheck hooks — which is why they carry
// an explicit guard against exactly these tokens.
for (const [token] of root.matchAll(/\{\{[A-Z_]+\}\}/g))
  fail(
    `AGENTS.md still carries the unrendered placeholder ${token} — give it a value or drop the line.`,
  )

// ---------------------------------------------------------------------------
// 3. The Task Router: every topic file has a row, and every routed path is real.
// ---------------------------------------------------------------------------
const ROUTER = "## Task Router"
const routerSection = (() => {
  const start = root.indexOf(ROUTER)
  if (start === -1) {
    fail(`AGENTS.md has no "${ROUTER}" section — it is how a task finds the doc that covers it.`)
    return ""
  }
  const rest = root.slice(start + ROUTER.length)
  const end = rest.indexOf("\n## ")
  return end === -1 ? rest : rest.slice(0, end)
})()

// Routed targets, read out of the LAST cell of each row — the `read` column — and never the whole
// row. The `task` column describes the task, so its backticks name concepts rather than files to
// open: a row reading "what a `CHANGE.md` is" points at no `CHANGE.md` in the repo root, and scanning
// it would fail the shipped template against its own checker.
//
// Within that cell, a backticked span counts as a path when it holds a `/` or ends in `.md`. That
// skips the other things a cell names — a skill, a command, a section — and skips globs,
// placeholders and URLs, none of which are checkable against the filesystem.
//
// Rows are split on UNESCAPED pipes: a cell may contain a literal `\|`, and splitting on every pipe
// picked the wrong "last cell", which could let a nonexistent path through unchecked.
const routedPaths = new Set()
for (const line of routerSection.split("\n")) {
  const row = line.trim()
  if (!row.startsWith("|")) continue
  const cells = row.split(/(?<!\\)\|/).slice(1, row.endsWith("|") ? -1 : undefined)
  const target = cells.at(-1)
  if (target === undefined) continue
  for (const [, span] of target.matchAll(/`([^`]+)`/g)) {
    if (!span.includes("/") && !span.endsWith(".md")) continue
    if (/[<>*~]/.test(span) || span.includes("://")) continue
    routedPaths.add(span.replace(/^\.\//, ""))
  }
}
for (const path of routedPaths)
  if (!existsSync(abs(path)))
    fail(`AGENTS.md's Task Router points at ${path}, which does not exist.`)

// Coverage: a topic file nothing routes to is a file nothing reads. Checked against the parsed
// `read` column, not against the section text — a topic file merely NAMED in a task description, or
// in prose beside the table, is not routed to, and accepting that made the check hollow.
const topicDir = "docs/agents"
const topics = existsSync(abs(topicDir))
  ? readdirSync(abs(topicDir))
      .sort()
      .filter((entry) => entry.endsWith(".md") && entry !== "CLAUDE.md")
  : []
for (const entry of topics)
  if (!routedPaths.has(`${topicDir}/${entry}`))
    fail(`${topicDir}/${entry} has no row in the AGENTS.md Task Router.`)

// ---------------------------------------------------------------------------
// 4. Command sync: every documented `pnpm <script>` is a real script.
// ---------------------------------------------------------------------------
// A command that has been renamed or deleted is worse than an undocumented one: it reads as verified.
// No package.json means no claim to check, not a failure — this ships into non-Node repos too.
const PNPM_BUILTINS = new Set([
  "add",
  "audit",
  "bin",
  "config",
  "create",
  "deploy",
  "dlx",
  "env",
  "exec",
  "fetch",
  "import",
  "init",
  "install",
  "licenses",
  "link",
  "list",
  "ls",
  "outdated",
  "pack",
  "patch",
  "prune",
  "publish",
  "rebuild",
  "remove",
  "root",
  "run",
  "server",
  "setup",
  "store",
  "unlink",
  "update",
  "why",
])
if (existsSync(abs("package.json"))) {
  const scripts = JSON.parse(read("package.json")).scripts ?? {}
  for (const [, name] of root.matchAll(/pnpm ([a-z][\w:.-]*)/g))
    if (!PNPM_BUILTINS.has(name) && !(name in scripts))
      fail(`AGENTS.md mentions \`pnpm ${name}\`, which is not a package.json script.`)
}

// ---------------------------------------------------------------------------
// 5. CLAUDE.md is a symlink, never a second copy.
// ---------------------------------------------------------------------------
// The harnesses load CLAUDE.md; AGENTS.md is the file. A materialized copy forks the corpus, and the
// fork is silent — both halves load, and the stale one wins wherever it was read last.
// Compared by DESTINATION, not by spelling. `AGENTS.md`, `./AGENTS.md`, an absolute path, and a path
// through a symlinked parent all name the same file, and rejecting any of them would fail a repo that
// is correctly set up. Only realpath on both sides gets that right — comparing the resolved path
// strings still trips over a symlinked ancestor, which is exactly how macOS spells its temp dirs.
const claudeMd = abs("CLAUDE.md")
let linkTarget = null // null = missing, false = a real file, string = the link text
try {
  linkTarget = lstatSync(claudeMd).isSymbolicLink() ? readlinkSync(claudeMd) : false
} catch {
  linkTarget = null
}
if (linkTarget === null) {
  fail("CLAUDE.md is missing — it must be a symlink pointing at AGENTS.md.")
} else if (linkTarget === false) {
  fail("CLAUDE.md is a real file — it must be a symlink to AGENTS.md, or the two copies diverge.")
} else {
  let sameFile = false
  try {
    sameFile = realpathSync(claudeMd) === realpathSync(abs("AGENTS.md"))
  } catch {
    sameFile = false // a dangling link resolves to nothing, and that is a failure too
  }
  if (!sameFile) fail(`CLAUDE.md links ${linkTarget} — it must resolve to AGENTS.md.`)
}

// ---------------------------------------------------------------------------
// 6. The record ceiling — declared the way the budget is, and opt-in.
// ---------------------------------------------------------------------------
// `Ceiling: **40 lines** per record` on one line of docs/decisions/README.md. A repo that declares
// nothing is not checked and not mentioned: records predate this pass in every repo it lands in, and a
// gate that lights an existing folder red on install day is one you switch off rather than meet. Each
// repo sets its own number for the same reason AGENTS.md does — it is editorial discipline, so it has
// to be chosen.
const ceilingReport = (() => {
  const readme = "docs/decisions/README.md"
  if (!existsSync(abs(readme))) return null
  const line = read(readme)
    .split("\n")
    .find((l) => l.includes("Ceiling:"))
  if (line === undefined) return null
  const declared = line
    .slice(line.indexOf("Ceiling:") + "Ceiling:".length)
    .replaceAll("*", "")
    .replaceAll("`", "")
  const parsed = /^\s*(\d[\d_]*)\s*lines?\b/i.exec(declared)
  if (parsed === null) {
    fail(
      `${readme}'s ceiling declaration is malformed: "${declared.trim()}". ` +
        "It must read `Ceiling: <N> lines` — anything after that is prose.",
    )
    return null
  }
  const maxLines = Number(parsed[1].replaceAll("_", ""))
  let records = 0
  let longest = 0
  // <NNNN>-<slug>.md only: README.md is the contract, not a record, and a stray note is not one either.
  for (const name of readdirSync(abs("docs/decisions")).sort()) {
    if (!/^\d{4}-.+\.md$/.test(name)) continue
    records += 1
    const lines = lineCount(read(`docs/decisions/${name}`))
    if (lines > longest) longest = lines
    if (lines > maxLines)
      fail(
        `docs/decisions/${name} is ${lines} lines — over the declared ${maxLines}-line ceiling. ` +
          "Keep the decision, the trade-off and the revisit trigger; the story of how you got there " +
          "belongs in the change's archive entry.",
      )
  }
  return `${records} record(s), longest ${longest}/${maxLines} lines`
})()

// ---------------------------------------------------------------------------
// 7. The topic-file ratchet — the corpus may shrink freely, and grows on purpose.
// ---------------------------------------------------------------------------
// docs/agents/ has no honest per-file ceiling: a topic is as long as its subject, so any number would
// be a guess. The baseline records what the corpus IS instead, and the check refuses a silent
// increase — growth stays legal and costs one visible `--update-baseline` in the diff. No threshold is
// chosen, so no threshold can be set too high.
//
// Words, not lines or bytes: a formatter that reflows Markdown moves both of those on a pure reformat
// and moves no words. README.md is excluded — it is the contract, shipped rather than written here, so
// a payload refresh must not read as the corpus growing.
//
// Opt-in like the ceiling: no baseline file means no check and no mention. Seed one with
// `--update-baseline`, which is also how a repo adopts this after the fact.
const BASELINE = "docs/agents/corpus.baseline.json"
const corpusReport = (() => {
  const measured = topics.filter((entry) => entry !== "README.md")
  const perFile = {}
  let words = 0
  for (const entry of measured) {
    const count = read(`${topicDir}/${entry}`).split(/\s+/).filter(Boolean).length
    perFile[entry] = count
    words += count
  }
  if (update) {
    // A re-record is not a green light. Passes 1 to 6 have already run, and exiting 0 here would let
    // `--update-baseline` in a repo that is failing something else report success — the one thing this
    // flag must never do, since it is reached for precisely when the build is red.
    if (failures.length > 0) {
      for (const failure of failures) console.error(`agents:check — ${failure}`)
      console.error("agents:check — refusing to re-record the baseline while the above fails.")
      process.exit(1)
    }
    // Without the directory, writeFileSync throws ENOENT with a stack trace and no advice.
    if (!existsSync(abs(topicDir))) {
      console.error(
        `agents:check — no ${topicDir}/ to ratchet, so there is no baseline to seed. Create it, ` +
          "give it a topic file and a Task Router row, then re-record.",
      )
      process.exit(1)
    }
    writeFileSync(
      abs(BASELINE),
      `${JSON.stringify(
        {
          $comment:
            "The recorded size of docs/agents/*.md excluding README.md, used as a ratchet by " +
            "check-agents-docs.mjs: the corpus may shrink freely and may only grow through a commit " +
            "that re-records this file with `--update-baseline`. No threshold is chosen here, so no " +
            "threshold can be set too high. Delete this file to switch the ratchet off.",
          words,
          perFile,
        },
        null,
        2,
      )}\n`,
    )
    console.log(
      `agents:check — baseline re-recorded at ${words} words across ${measured.length} topic file(s).`,
    )
    process.exit(0)
  }
  if (!existsSync(abs(BASELINE))) return null
  let baseline
  try {
    baseline = JSON.parse(read(BASELINE))
  } catch {
    fail(`${BASELINE} is not valid JSON. Re-record it with \`--update-baseline\`.`)
    return null
  }
  // Validated the way the corpus ratchet this is styled on validates its own: `Array.isArray` is the
  // check `typeof === "object"` misses, and the sum has to match, because a baseline whose `words` is
  // larger than its parts disables the ratchet while reporting green — the one failure mode that looks
  // exactly like success.
  const malformed = (why) => {
    fail(`${BASELINE} is malformed — ${why}. Re-record it with \`--update-baseline\`.`)
    return null
  }
  if (baseline === null || typeof baseline !== "object" || Array.isArray(baseline))
    return malformed("it must be a JSON object")
  if (!Number.isInteger(baseline.words) || baseline.words < 0)
    return malformed("`words` must be a non-negative integer")
  if (
    typeof baseline.perFile !== "object" ||
    baseline.perFile === null ||
    Array.isArray(baseline.perFile)
  )
    return malformed("`perFile` must be an object")
  const recorded = Object.values(baseline.perFile).reduce((total, n) => total + n, 0)
  if (recorded !== baseline.words)
    return malformed(`\`words\` says ${baseline.words} and \`perFile\` sums to ${recorded}`)
  if (words > baseline.words) {
    const grown = measured
      .filter((entry) => perFile[entry] > (baseline.perFile?.[entry] ?? 0))
      .map((entry) => `${entry} ${baseline.perFile?.[entry] ?? 0}→${perFile[entry]}`)
    fail(
      `docs/agents/ is ${words} words, baseline ${baseline.words}, +${words - baseline.words}. ` +
        `Grown: ${grown.join(", ") || "none named"}. Cut it back out, or record the growth on ` +
        "purpose with `--update-baseline` in the same commit.",
    )
  }
  return `${words}/${baseline.words} topic words`
})()

// ---------------------------------------------------------------------------

if (failures.length > 0) {
  for (const failure of failures) console.error(`agents:check — ${failure}`)
  process.exit(1)
}
// The root is in the success line on purpose: it is the one input every check above depends on, and a
// wrong one produces confident, wrong output. Naming it makes that visible instead of inferable.
console.log(
  `agents:check — ${repoRoot}: ${budgetReport}; ${topics.length} topic file(s), ${routedPaths.size} routed path(s)` +
    `${corpusReport === null ? "" : `; ${corpusReport}`}` +
    `${ceilingReport === null ? "" : `; ${ceilingReport}`}.`,
)
