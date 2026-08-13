#!/usr/bin/env node
// Guards the agent-docs contract in a repo scaffolded by dw-init: AGENTS.md is the one always-loaded
// file, it stays inside a budget it declares itself, and everything it routes to is real.
//
// Zero dependencies, Node built-ins only — it ships into repos that may have no package.json at all.
// Run it as `node scripts/check-agents-docs.mjs`, or via the `agents:check` script dw-init wires.
//
// Deliberately NOT here: any check over docs/decisions/. Those records are numbered, superseded and
// retired by hand and by dw-land, and a validator over them turns an editorial layer into a build
// gate — a commit blocked because a decision record is shaped wrong teaches you to stop writing them.
// If you add one anyway, add it knowing that is the trade.
import {
  existsSync,
  lstatSync,
  readFileSync,
  readdirSync,
  readlinkSync,
  realpathSync,
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

const failures = []
const fail = (message) => failures.push(message)
const abs = (path) => join(repoRoot, path)
const read = (path) => readFileSync(abs(path), "utf8")

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
  const lines = root.split("\n").length
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

if (failures.length > 0) {
  for (const failure of failures) console.error(`agents:check — ${failure}`)
  process.exit(1)
}
// The root is in the success line on purpose: it is the one input every check above depends on, and a
// wrong one produces confident, wrong output. Naming it makes that visible instead of inferable.
console.log(
  `agents:check — ${repoRoot}: ${budgetReport}; ${topics.length} topic file(s), ${routedPaths.size} routed path(s).`,
)
