// routing.ts — Tier 2 of the routing evals. Deterministic, dependency-free, free to run.
//
// The question it answers: does each skill still rank first for its own vocabulary, or has a
// neighbour's description drifted far enough to steal it? It scores every case prompt against the
// corpus of `name: description` pairs with TF-IDF + cosine and prints the ranking.
//
// This is a LEXICAL PROXY, not the router. The real router is a model reading the same lines with
// far more context, and it is allowed to disagree — `evals/trigger.ts` is the tier that asks it.
// What this tier buys is a check that runs in CI on every push for zero tokens and catches the one
// failure mode that matters: two descriptions competing for the same words. A skill that stops
// ranking for its own vocabulary here is a description bug regardless of what the router does.
//
// Usage:
//   node evals/routing.ts                 every case file under evals/cases/
//   node evals/routing.ts dw-shape        only these skills
//   node evals/routing.ts --top 5         how many ranked skills to show per prompt
//
// No build step: Node strips the types natively (>=22.18; this repo pins 24 in .nvmrc). That is
// also the constraint on the syntax here — erasable constructs only, so no enum, no parameter
// properties, no namespace.

import { existsSync, readdirSync, readFileSync } from "node:fs"
import { basename, dirname, join } from "node:path"

const ROOT = dirname(import.meta.dirname)
const SKILLS_DIR = join(ROOT, "skills")
const CASES_DIR = join(ROOT, "evals", "cases")

type SkillDoc = {
  name: string
  description: string
  explicit: boolean
  /** What the eval actually scores. See buildCorpus for why it is name + description. */
  text: string
}

type Positive = { prompt: string; note?: string }
type Negative = { prompt: string; owner: string; note?: string }

type CaseFile = {
  skill: string
  note?: string
  positives: Positive[]
  negatives: Negative[]
}

type Vector = Map<string, number>

type Index = {
  names: string[]
  idf: Map<string, number>
  vectors: Map<string, Vector>
}

type Ranked = { skill: string; score: number }

function fail(message: string): never {
  console.error(`routing.ts: ${message}`)
  process.exit(2)
}

// --- frontmatter -------------------------------------------------------------

/**
 * The two-space-indented `description: >-` folded scalar every SKILL.md uses, plus plain and
 * quoted single-line values. Deliberately not a YAML parser: the frontmatter shape here is fixed
 * by docs/SKILL-ANATOMY.md and a dependency for four keys would be the tail wagging the dog.
 */
function parseFrontmatter(src: string): Map<string, string> {
  const out = new Map<string, string>()
  const lines = src.split(/\r?\n/)
  if (lines[0]?.trim() !== "---") return out

  let i = 1
  while (i < lines.length && lines[i].trim() !== "---") {
    const match = /^([A-Za-z][A-Za-z0-9_-]*):[ \t]*(.*)$/.exec(lines[i])
    if (!match) {
      i++
      continue
    }
    const key = match[1]
    const inline = match[2].trim()

    if (inline === ">" || inline === ">-" || inline === ">+" || inline === "|" || inline === "|-") {
      const folded: string[] = []
      i++
      // Continuation lines are indented; the next zero-indent line is the next key.
      while (i < lines.length && lines[i].trim() !== "---") {
        if (lines[i].trim() !== "" && !/^[ \t]/.test(lines[i])) break
        folded.push(lines[i].trim())
        i++
      }
      const joined = inline.startsWith(">") ? folded.join(" ") : folded.join("\n")
      out.set(key, joined.replace(/[ \t]+/g, " ").trim())
      continue
    }

    out.set(key, stripQuotes(inline))
    i++
  }
  return out
}

function stripQuotes(value: string): string {
  if (value.length >= 2) {
    const first = value[0]
    const last = value[value.length - 1]
    if ((first === '"' || first === "'") && first === last) return value.slice(1, -1)
  }
  return value
}

// --- tokenizing --------------------------------------------------------------

// Ordinary English function words, kept as one whitespace-split string so the list stays legible.
// Note what is NOT here: the "Use when someone says ..." phrasing every description shares. It needs
// no list — a term carried by all N documents gets idf log(1) = 0 and drops out arithmetically.
const STOPWORDS = new Set(
  `a about after again against all also am an and any are as at be because been before being below
   between both but by can did do does doing down during each else few for from further had has have
   having he her here hers him his how i if in into is it its itself just me more most my no nor not
   now of off on once only or other ought our ours out over own same she should so some such than
   that the their theirs them then there these they this those through to too under until up very
   was we were what when where which while who whom why will with would you your yours`.split(
    /\s+/,
  ),
)

const VOWEL = /[aeiouy]/

// Longest first: the loop takes the first match and stops.
const DERIVATIONAL: [string, string][] = [
  ["ization", "ize"],
  ["ational", "ate"],
  ["fulness", "ful"],
  ["ousness", "ous"],
  ["iveness", "ive"],
  ["ibility", "ible"],
  ["ability", "able"],
  ["tional", "tion"],
  ["ation", "ate"],
  ["ement", ""],
  ["ivity", "ive"],
  ["ment", ""],
  ["ness", ""],
  ["able", ""],
  ["ible", ""],
  ["ance", ""],
  ["ence", ""],
  ["ical", "ic"],
  ["ally", "al"],
  ["ity", ""],
  ["er", ""],
]

/**
 * A suffix stripper, not a linguist's stemmer. It exists so `shape` / `shaping` / `shaped` land on
 * one term, and it is wrong in places (`decision` and `decide` never meet). That is tolerable
 * because both the corpus and the query go through this same function: the eval compares documents
 * against each other, so consistency buys more than accuracy would. scripts/tests/ pins the cases
 * that matter, so a change here shows up as a test diff rather than as quiet ranking drift.
 */
function stem(word: string): string {
  let w = word

  // 1 — plurals.
  if (w.endsWith("ies") && w.length > 4) w = `${w.slice(0, -3)}y`
  else if (w.endsWith("sses")) w = w.slice(0, -2)
  else if (w.endsWith("ss") || w.endsWith("us") || w.endsWith("is")) {
    // Not a plural: leave `class`, `status`, `analysis` alone.
  } else if (w.endsWith("s") && w.length > 3) w = w.slice(0, -1)

  // 2 — derivational endings. The length guard keeps `user` from collapsing to `us`.
  for (const [suffix, replacement] of DERIVATIONAL) {
    if (w.endsWith(suffix) && w.length - suffix.length >= 3) {
      w = w.slice(0, -suffix.length) + replacement
      break
    }
  }

  // 3 — verb endings, then the doubled consonant stripping one exposes (`committing` -> `commit`).
  for (const suffix of ["ing", "ed"]) {
    if (!w.endsWith(suffix)) continue
    const shortened = w.slice(0, -suffix.length)
    if (shortened.length >= 3 && VOWEL.test(shortened)) {
      w = shortened
      const last = w[w.length - 1]
      if (last === w[w.length - 2] && !"lsz".includes(last)) w = w.slice(0, -1)
    }
    break
  }

  // 4 — adverbs.
  if (w.endsWith("ly") && w.length > 4) w = w.slice(0, -2)

  // 5 — a trailing silent e, so phase 3's output meets the bare verb: shape/shaping, route/routing.
  if (w.endsWith("e") && w.length >= 4) w = w.slice(0, -1)

  return w
}

function tokenize(text: string): string[] {
  const out: string[] = []
  const words = text
    .toLowerCase()
    .replace(/['’]/g, "")
    .split(/[^a-z0-9]+/)
  for (const word of words) {
    if (word.length < 2 || STOPWORDS.has(word)) continue
    const stemmed = stem(word)
    if (stemmed.length >= 2 && !STOPWORDS.has(stemmed)) out.push(stemmed)
  }
  return out
}

// --- corpus and index --------------------------------------------------------

function buildCorpus(): SkillDoc[] {
  if (!existsSync(SKILLS_DIR)) fail(`no skills/ directory at ${SKILLS_DIR}`)

  const docs: SkillDoc[] = []
  const names = readdirSync(SKILLS_DIR, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort()

  for (const name of names) {
    const path = join(SKILLS_DIR, name, "SKILL.md")
    if (!existsSync(path)) continue
    const fm = parseFrontmatter(readFileSync(path, "utf8"))
    const description = fm.get("description") ?? ""
    if (description === "") fail(`skills/${name}/SKILL.md has no description in its frontmatter`)
    const declared = fm.get("name")
    if (declared !== undefined && declared !== name) {
      fail(`skills/${name}/SKILL.md declares name: ${declared} — directory and name must agree`)
    }
    docs.push({
      name,
      description,
      explicit: fm.get("disable-model-invocation") === "true",
      // Name plus description, and nothing else. That is the whole surface the router chooses
      // from — a listing of `name: description` lines, no argument-hint and no body — so scoring
      // more than that would measure something the real decision never sees.
      text: `${name} ${description}`,
    })
  }
  if (docs.length === 0) fail("found no skills to score against")
  return docs
}

/** Sublinear tf * idf, L2-normalised. Terms with idf 0 (in every document) are dropped. */
function weigh(tokens: string[], idf: Map<string, number>): Vector {
  const counts = new Map<string, number>()
  for (const token of tokens) counts.set(token, (counts.get(token) ?? 0) + 1)

  const vector: Vector = new Map()
  for (const [term, count] of counts) {
    const weight = idf.get(term)
    if (weight === undefined || weight === 0) continue
    // A description that says "commit" three times is not three times more about committing.
    vector.set(term, (1 + Math.log(count)) * weight)
  }

  let sumOfSquares = 0
  for (const value of vector.values()) sumOfSquares += value * value
  const norm = Math.sqrt(sumOfSquares)
  if (norm === 0) return new Map()
  for (const [term, value] of vector) vector.set(term, value / norm)
  return vector
}

function buildIndex(docs: SkillDoc[]): Index {
  const tokens = new Map<string, string[]>()
  for (const doc of docs) tokens.set(doc.name, tokenize(doc.text))

  const df = new Map<string, number>()
  for (const list of tokens.values()) {
    for (const term of new Set(list)) df.set(term, (df.get(term) ?? 0) + 1)
  }

  const idf = new Map<string, number>()
  for (const [term, count] of df) idf.set(term, Math.log(docs.length / count))

  const vectors = new Map<string, Vector>()
  for (const [name, list] of tokens) vectors.set(name, weigh(list, idf))

  return { names: docs.map((doc) => doc.name), idf, vectors }
}

/** Both sides are L2-normalised, so the dot product already is the cosine. */
function cosine(a: Vector, b: Vector): number {
  const [small, large] = a.size <= b.size ? [a, b] : [b, a]
  let dot = 0
  for (const [term, value] of small) {
    const other = large.get(term)
    if (other !== undefined) dot += value * other
  }
  return dot
}

function rank(index: Index, prompt: string): Ranked[] {
  const query = weigh(tokenize(prompt), index.idf)
  const scored = index.names.map((skill) => ({
    skill,
    score: cosine(query, index.vectors.get(skill) ?? new Map()),
  }))
  // Name-ordered tiebreak, so two runs of the same corpus print the same thing.
  scored.sort((a, b) => b.score - a.score || a.skill.localeCompare(b.skill))
  return scored
}

// --- case files --------------------------------------------------------------

function loadCases(filter: string[]): CaseFile[] {
  if (!existsSync(CASES_DIR)) fail(`no case directory at ${CASES_DIR}`)

  const files = readdirSync(CASES_DIR)
    .filter((name) => name.endsWith(".json"))
    .sort()
  const cases: CaseFile[] = []

  for (const file of files) {
    const skill = basename(file, ".json")
    if (filter.length > 0 && !filter.includes(skill)) continue

    const path = join(CASES_DIR, file)
    let parsed: CaseFile
    try {
      parsed = JSON.parse(readFileSync(path, "utf8")) as CaseFile
    } catch (error) {
      return fail(`evals/cases/${file} is not valid JSON: ${(error as Error).message}`)
    }
    if (parsed.skill !== skill) {
      fail(`evals/cases/${file} declares skill "${parsed.skill}" — it must match the filename`)
    }
    if (!Array.isArray(parsed.positives) || parsed.positives.length === 0) {
      fail(`evals/cases/${file} has no positives`)
    }
    for (const negative of parsed.negatives ?? []) {
      if (!negative.owner) fail(`evals/cases/${file}: negative "${negative.prompt}" has no owner`)
    }
    cases.push({ ...parsed, negatives: parsed.negatives ?? [] })
  }

  const missing = filter.filter((name) => !cases.some((entry) => entry.skill === name))
  if (missing.length > 0) fail(`no case file for: ${missing.join(", ")}`)
  if (cases.length === 0) fail("no case files found under evals/cases/")
  return cases
}

// --- reporting ---------------------------------------------------------------

function fmt(score: number): string {
  return score.toFixed(3)
}

function others(ranked: Ranked[], skip: string, top: number): string {
  const rest = ranked.filter((entry) => entry.skill !== skip && entry.score > 0).slice(0, top)
  if (rest.length === 0) return "nothing else scored"
  return rest.map((entry) => `${entry.skill} ${fmt(entry.score)}`).join(" · ")
}

type Tally = { skill: string; rank1: number; positives: number; negOk: number; negatives: number }

function report(cases: CaseFile[], index: Index, top: number): Tally[] {
  const tallies: Tally[] = []

  for (const entry of cases) {
    if (!index.vectors.has(entry.skill)) {
      fail(`evals/cases/${entry.skill}.json has no matching skills/${entry.skill}/SKILL.md`)
    }
    const tally: Tally = {
      skill: entry.skill,
      rank1: 0,
      positives: entry.positives.length,
      negOk: 0,
      negatives: entry.negatives.length,
    }

    console.log(`\n▸ ${entry.skill}`)

    for (const positive of entry.positives) {
      const ranked = rank(index, positive.prompt)
      const position = ranked.findIndex((r) => r.skill === entry.skill) + 1
      const own = ranked[position - 1]
      const winner = ranked[0]

      if (own.score === 0) {
        // Every ranking below is meaningless when the prompt shares no discriminating term with
        // any description, so say that instead of printing an alphabetical ordering as a result.
        console.log(`  ✗ no signal    "${positive.prompt}"`)
        console.log("      └ no term in this prompt discriminates between descriptions")
        continue
      }

      if (position === 1) {
        tally.rank1++
        console.log(`  ✓ rank 1  ${fmt(own.score)}  "${positive.prompt}"`)
        console.log(`      └ then ${others(ranked, entry.skill, top - 1)}`)
      } else {
        console.log(`  ✗ rank ${position}  ${fmt(own.score)}  "${positive.prompt}"`)
        console.log(`      └ lost to ${winner.skill} ${fmt(winner.score)}`)
      }
    }

    for (const negative of entry.negatives) {
      const ranked = rank(index, negative.prompt)
      const mine = ranked.find((r) => r.skill === entry.skill)?.score ?? 0
      const owner = ranked.find((r) => r.skill === negative.owner)
      if (owner === undefined) {
        fail(
          `evals/cases/${entry.skill}.json names owner "${negative.owner}", which is not a skill`,
        )
      }
      // The bar is only that this skill does not outrank the owner. Whether the owner takes rank 1
      // outright is that owner's own case file to assert.
      if (mine < owner.score) {
        tally.negOk++
        console.log(
          `  ✓ yields  ${fmt(mine)} < ${negative.owner} ${fmt(owner.score)}  "${negative.prompt}"`,
        )
      } else {
        console.log(
          `  ✗ steals  ${fmt(mine)} ≥ ${negative.owner} ${fmt(owner.score)}  "${negative.prompt}"`,
        )
      }
    }

    tallies.push(tally)
  }

  return tallies
}

function summarise(tallies: Tally[], corpusSize: number, scored: number): void {
  const width = Math.max(...tallies.map((t) => t.skill.length), 5)
  console.log(`\n${"skill".padEnd(width)}  rank-1   yields`)
  console.log(`${"-".repeat(width)}  -------  -------`)

  let rank1 = 0
  let positives = 0
  let negOk = 0
  let negatives = 0
  for (const tally of tallies) {
    rank1 += tally.rank1
    positives += tally.positives
    negOk += tally.negOk
    negatives += tally.negatives
    const a = `${tally.rank1}/${tally.positives}`
    const b = `${tally.negOk}/${tally.negatives}`
    console.log(`${tally.skill.padEnd(width)}  ${a.padEnd(7)}  ${b}`)
  }

  const pct = positives === 0 ? 0 : Math.round((rank1 / positives) * 100)
  console.log(`${"-".repeat(width)}  -------  -------`)
  console.log(
    `${"TOTAL".padEnd(width)}  ${`${rank1}/${positives}`.padEnd(7)}  ${negOk}/${negatives}`,
  )
  console.log(`\nrank-1 ${pct}% · ${scored} of ${corpusSize} skills have case files`)
}

// --- entry point -------------------------------------------------------------

function main(argv: string[]): void {
  let top = 3
  const filter: string[] = []

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (arg === "--top") {
      const value = Number(argv[++i])
      if (!Number.isInteger(value) || value < 1) fail("--top needs a positive integer")
      top = value
    } else if (arg === "-h" || arg === "--help") {
      console.log("usage: node evals/routing.ts [--top <n>] [skill...]")
      return
    } else if (arg.startsWith("-")) {
      fail(`unknown flag ${arg}`)
    } else {
      filter.push(arg)
    }
  }

  const docs = buildCorpus()
  const index = buildIndex(docs)
  const cases = loadCases(filter)

  const explicit = docs.filter((doc) => doc.explicit).map((doc) => doc.name)
  console.log(
    `corpus: ${docs.length} skills (${explicit.length} explicit-invoke, scored against but`,
  )
  console.log(`        never expected to win: ${explicit.join(", ")})`)

  const tallies = report(cases, index, top)
  summarise(tallies, docs.length, cases.length)
}

main(process.argv.slice(2))
