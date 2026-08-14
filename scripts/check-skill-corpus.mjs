#!/usr/bin/env node
// The ratchet over `skills/*/SKILL.md`: the corpus may shrink freely, and may only grow through a
// commit that also re-records the baseline. Pass 3 of scripts/validate-artifacts.sh.
//
// It sets no threshold, which is the whole point — a threshold is a taste number, and a taste number
// set once is set too high forever. The baseline records what the corpus IS; the check refuses a
// silent increase. Growth stays legal and costs one visible `--update-baseline` in the diff.
//
// Words, not bytes or lines: prettier reflows Markdown at 100 columns, so a pure reformat moves both
// of those and moves no words. The unit also continues the 11 116 that `de-ratchet-the-solo-lane`
// recorded.
//
// Repo tooling, never shipped — no plugin owns it, so it stays out of templates/ and out of the
// hooks. Zero dependencies, Node built-ins only, styled on templates/check-agents-docs.mjs.
import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"

const BASELINE = "scripts/skill-corpus.baseline.json"
const SKILLS = "skills"

const die = (message) => {
  console.error(`::error::skill-corpus — ${message}`)
  process.exit(2)
}

// --root exists for the self-test, which must drive synthetic fixtures rather than the live tree.
// Without it every case would assert against this repo's real corpus and the test would be a second
// content gate wearing a unit test's name.
const args = process.argv.slice(2)
const update = args.includes("--update-baseline")
const rootFlag = args.indexOf("--root")

// Every flag is spelled out, and anything unrecognised is fatal rather than ignored. Two silent
// failures live here, and both look like success: a typo'd `--update-baselines` runs a plain CHECK
// and writes nothing, and an empty `--root ""` (an unset shell variable, quoted) resolves the
// baseline RELATIVE TO THE CWD — so from the repo root it measures, and with --update-baseline
// rewrites, the live tracked baseline while the caller believes it named a fixture.
const KNOWN = new Set(["--update-baseline", "--root"])
for (const [i, arg] of args.entries()) {
  if (rootFlag !== -1 && i === rootFlag + 1) continue // this one is --root's value
  if (!KNOWN.has(arg))
    die(`unexpected argument ${JSON.stringify(arg)}. Usage: [--root <dir>] [--update-baseline].`)
}
if (rootFlag !== -1) {
  const value = args[rootFlag + 1]
  if (value === undefined || value === "" || value.startsWith("-"))
    die(
      `--root needs a directory, got ${JSON.stringify(value ?? null)}. An empty or flag-shaped value ` +
        "would silently measure the current working tree instead.",
    )
}

// `.git` is a directory in a clone and a FILE in a worktree, so existsSync is the right probe for
// both — same walk as check-agents-docs.mjs, and the same reason.
const findUp = () => {
  let dir = dirname(fileURLToPath(import.meta.url))
  for (;;) {
    if (existsSync(join(dir, ".git"))) return dir
    const up = dirname(dir)
    if (up === dir) return null
    dir = up
  }
}

const root = rootFlag === -1 ? findUp() : args[rootFlag + 1]
if (root === null) die("no --root given and no .git at or above this script.")

// The seed a bootstrap writes. Short on purpose: the full rationale lives in docs/agents/tooling.md
// and in docs/decisions/, and a comment that restates them drifts from both.
const SEED_COMMENT =
  "Recorded size of skills/*/SKILL.md, used as a ratchet by scripts/check-skill-corpus.mjs: the " +
  "corpus may shrink freely and may only grow through a commit that re-records this file with " +
  "`node scripts/check-skill-corpus.mjs --update-baseline`. Words, not bytes or lines, so a prettier " +
  "reflow does not move the number. Why it exists: docs/agents/tooling.md."

// Exit 2, not 1, and never a silent pass: a checker that cannot read its own baseline knows nothing
// about the corpus, and reporting that as "within budget" is the one failure mode a ratchet cannot
// survive. The single exception is being ASKED to create one — `--update-baseline` on a missing file
// bootstraps it, because the old behaviour was to refuse while advising the very flag that just
// failed, which left no way to regenerate a deleted baseline at all.
const baselinePath = join(root, BASELINE)
let baseline
if (!existsSync(baselinePath)) {
  if (!update) die(`no baseline at ${BASELINE}. Create it with --update-baseline.`)
  baseline = { $comment: SEED_COMMENT }
} else {
  try {
    baseline = JSON.parse(readFileSync(baselinePath, "utf8"))
  } catch (error) {
    die(`${BASELINE} is not valid JSON: ${error.message}`)
  }
  // Array.isArray is the check `typeof === "object"` misses: [] satisfies it, and every lookup into
  // an array by skill name then yields undefined, so a malformed baseline reads as valid while every
  // skill silently resolves to 0.
  if (
    !Number.isInteger(baseline.words) ||
    baseline.words < 0 ||
    typeof baseline.perSkill !== "object" ||
    baseline.perSkill === null ||
    Array.isArray(baseline.perSkill)
  )
    die(
      `${BASELINE} is malformed — it needs a non-negative integer \`words\` and an object \`perSkill\`.`,
    )
  // A baseline whose halves disagree still gates on `words`, but names no skill in the failure —
  // the report promises a file to open and delivers a number to argue with. Refuse it instead.
  const recorded = Object.values(baseline.perSkill).reduce((total, n) => total + n, 0)
  if (recorded !== baseline.words)
    die(
      `${BASELINE} is inconsistent: \`words\` says ${baseline.words}, \`perSkill\` sums to ${recorded}. ` +
        "Re-record it with --update-baseline rather than editing either number by hand.",
    )
}

// Whitespace-separated runs over the WHOLE file, frontmatter included, so the number a reader can
// reproduce is the obvious one: `cat skills/*/SKILL.md | wc -w`.
//
// ASCII whitespace only, and NOT `\s`: JavaScript's `\s` also matches NBSP, the en/em spaces and the
// BOM, while `wc -w` under this repo's exported LC_ALL=C does not treat any of them as a separator.
// With `\s` a single pasted NBSP made the checker count one word more than the command the baseline
// tells you to verify it with — a phantom +1 you cannot see, in a diff that looks whitespace-only.
// The corpus holds none of those code points today, so this spelling changes no current number.
const countWords = (text) => text.split(/[ \t\n\v\f\r]+/).filter((run) => run !== "").length

const skillsDir = join(root, SKILLS)
if (!existsSync(skillsDir)) die(`no ${SKILLS}/ directory under ${root}.`)
const perSkill = {}
for (const name of readdirSync(skillsDir).sort()) {
  const file = join(skillsDir, name, "SKILL.md")
  if (existsSync(file)) perSkill[name] = countWords(readFileSync(file, "utf8"))
}
const words = Object.values(perSkill).reduce((total, n) => total + n, 0)

if (update) {
  writeFileSync(baselinePath, `${JSON.stringify({ ...baseline, words, perSkill }, null, 2)}\n`)
  console.log(
    `skill-corpus — baseline re-recorded at ${words} words across ${Object.keys(perSkill).length} skill(s).`,
  )
  process.exit(0)
}

const delta = words - baseline.words
if (delta > 0) {
  // Naming the skills that account for the delta is the difference between a number to argue with and
  // a file to open. A skill absent from the baseline is growth too, and reads as `new`.
  const grew = Object.keys(perSkill)
    .filter((name) => perSkill[name] > (baseline.perSkill[name] ?? 0))
    .sort(
      (a, b) =>
        perSkill[b] - (baseline.perSkill[b] ?? 0) - (perSkill[a] - (baseline.perSkill[a] ?? 0)),
    )
  console.error(
    `::error::skill-corpus — ${words} words, baseline ${baseline.words}, +${delta}. The corpus may only`,
  )
  console.error(
    `::error::  shrink on its own. Cut ${delta} word(s) back out, or record the growth on purpose with`,
  )
  console.error(
    "::error::  `node scripts/check-skill-corpus.mjs --update-baseline` in the same commit.",
  )
  for (const name of grew) {
    const was = baseline.perSkill[name]
    const from = was === undefined ? "new" : `was ${was}`
    console.error(
      `::error::  • ${name}: ${perSkill[name]} (${from}, +${perSkill[name] - (was ?? 0)})`,
    )
  }
  process.exit(1)
}

console.log(
  `• skills/: ${words} words, baseline ${baseline.words}${delta === 0 ? "" : ` (${delta})`}`,
)
// A shrink is the direction the ratchet wants, so it passes — but an unrecorded one leaves the
// baseline slack, and slack is room the next append spends without anybody deciding to.
if (delta < 0)
  console.log(
    `  now smaller by ${-delta} — re-record with --update-baseline to tighten the ratchet, or the slack is free growth later.`,
  )
