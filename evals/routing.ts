// routing.ts — the routing eval. Deterministic, dependency-free, free to run.
//
// The question it answers: does each skill still rank first for its own vocabulary, or has a
// neighbour's description drifted far enough to steal it? It scores every case prompt against the
// corpus of `name: description` pairs with TF-IDF + cosine and prints the ranking.
//
// This is a LEXICAL PROXY, not the router. The real router is a model reading the same lines with
// far more context, and it is allowed to disagree — asking it is a by-hand `claude -p` exercise, not
// something this repo ships. What this buys is a check that runs in CI on every push for zero tokens
// and catches the one
// failure mode that matters: two descriptions competing for the same words. A skill that stops
// ranking for its own vocabulary here is a description bug regardless of what the router does.
//
// Usage:
//   node evals/routing.ts                 every case file under evals/cases/
//   node evals/routing.ts dw-shape        only these skills
//   node evals/routing.ts --top 5         how many ranked skills to show per prompt
//   node evals/routing.ts --explain "…"   score one prompt out loud instead of running the eval
//
// No build step: Node strips the types natively (>=22.18; this repo pins 24 in devEngines.runtime,
// which is the version `pnpm eval:routing` runs on — a bare `node` may be older). That is also the
// constraint on the syntax here — erasable constructs only, so no enum, no parameter properties, no
// namespace.

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
  /**
   * `disable-model-invocation: true` skills. They stay in the corpus — they compete for the same
   * words and belong in the collision scan — but the model is never offered them, so one of them
   * outranking a skill is overlap to report, not a routing failure to count.
   */
  explicit: Set<string>
}

type Ranked = { skill: string; score: number }

function fail(message: string): never {
  console.error(`routing.ts: ${message}`)
  process.exit(2)
}

// --- frontmatter -------------------------------------------------------------

/**
 * The two-space-indented `description: >-` folded scalar every SKILL.md uses, plus plain and
 * quoted single-line values. Deliberately not a YAML parser: the frontmatter shape here is uniform
 * across every skill on disk, and a dependency for four keys would be the tail wagging the dog.
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
// no list because `log(N/df)` prices it down on its own — `use` sits in 7 of 11 descriptions and
// `say` in 5, so both are cheap rather than free. A term carried by *all* N would reach idf 0 and
// drop out outright; nothing in this corpus actually does, so the mechanism is a gradient, not a
// filter. Either way there is no hand-kept boilerplate list to rot.
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
 * against each other, so consistency buys more than accuracy would. What keeps a change here from
 * drifting quietly is the recorded baseline in evals/README.md plus the --min-rank1 floor CI passes:
 * touch this function and the numbers move, which is the intended way to find out.
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

function splitWords(text: string): string[] {
  return text
    .toLowerCase()
    .replace(/['’]/g, "")
    .split(/[^a-z0-9]+/)
}

/** Why a raw word did or did not become a query term. Only --explain reads the fate. */
type Fate = "kept" | "short" | "stopword" | "stem-stopword"

type Classified = { word: string; stem: string; fate: Fate }

/**
 * The keep-or-drop rule for one word, stated once. `tokenize` is this function plus a filter, so the
 * explanation --explain prints cannot describe a rule the eval does not actually apply.
 */
function classify(word: string): Classified {
  if (word.length < 2) return { word, stem: "", fate: "short" }
  if (STOPWORDS.has(word)) return { word, stem: "", fate: "stopword" }
  const stemmed = stem(word)
  if (stemmed.length < 2) return { word, stem: stemmed, fate: "short" }
  if (STOPWORDS.has(stemmed)) return { word, stem: stemmed, fate: "stem-stopword" }
  return { word, stem: stemmed, fate: "kept" }
}

function tokenize(text: string): string[] {
  const out: string[] = []
  for (const word of splitWords(text)) {
    const classified = classify(word)
    if (classified.fate === "kept") out.push(classified.stem)
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

  return {
    names: docs.map((doc) => doc.name),
    idf,
    vectors,
    explicit: new Set(docs.filter((doc) => doc.explicit).map((doc) => doc.name)),
  }
}

const COLLIDE_WARN = 0.5
const COLLIDE_ERROR = 0.75

type Collision = { a: string; b: string; score: number }

/**
 * Every pair of descriptions scored against each other. Two skills that read as near-duplicates to
 * TF-IDF read as near-duplicates to whatever picks between them, so this is the check that does not
 * depend on anyone having written a case prompt for the overlap yet.
 */
function findCollisions(index: Index): Collision[] {
  const found: Collision[] = []
  for (let i = 0; i < index.names.length; i++) {
    for (let j = i + 1; j < index.names.length; j++) {
      const a = index.names[i]
      const b = index.names[j]
      const score = cosine(index.vectors.get(a) ?? new Map(), index.vectors.get(b) ?? new Map())
      found.push({ a, b, score })
    }
  }
  found.sort((x, y) => y.score - x.score || x.a.localeCompare(y.a) || x.b.localeCompare(y.b))
  return found
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

type Tally = {
  skill: string
  rank1: number
  positives: number
  negOk: number
  negatives: number
  /** Negatives where neither side scored at all. Its own failure, because "steals" would misname it. */
  negBlank: number
  /** Positives where an explicit-invoke skill scored higher. Reported, never counted as a failure. */
  shadowed: number
}

function report(cases: CaseFile[], index: Index, top: number): Tally[] {
  const tallies: Tally[] = []

  for (const entry of cases) {
    if (!index.vectors.has(entry.skill)) {
      fail(`evals/cases/${entry.skill}.json has no matching skills/${entry.skill}/SKILL.md`)
    }
    // The case-file contract used to have its own validator; this is the half of it that survived,
    // and it is here rather than there because without the check the skill is absent from the ranked
    // field below and the lookup walks off the front of the array.
    if (index.explicit.has(entry.skill)) {
      fail(
        `evals/cases/${entry.skill}.json exists but skills/${entry.skill}/ is ` +
          "disable-model-invocation — routing is never the model's decision there",
      )
    }
    const tally: Tally = {
      skill: entry.skill,
      rank1: 0,
      positives: entry.positives.length,
      negOk: 0,
      negatives: entry.negatives.length,
      negBlank: 0,
      shadowed: 0,
    }

    console.log(`\n▸ ${entry.skill}`)

    for (const positive of entry.positives) {
      const ranked = rank(index, positive.prompt)
      // Rank among the skills the model is actually offered. An explicit-invoke skill cannot be
      // chosen, so letting one occupy first place would fail a prompt over an impossible loss.
      const field = ranked.filter((entry_) => !index.explicit.has(entry_.skill))
      const position = field.findIndex((r) => r.skill === entry.skill) + 1
      const own = field[position - 1]
      const winner = field[0]

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
        console.log(`      └ then ${others(field, entry.skill, top - 1)}`)
      } else {
        console.log(`  ✗ rank ${position}  ${fmt(own.score)}  "${positive.prompt}"`)
        console.log(`      └ lost to ${winner.skill} ${fmt(winner.score)}`)
      }

      const shadows = ranked.filter((r) => index.explicit.has(r.skill) && r.score > own.score)
      if (shadows.length > 0) {
        tally.shadowed++
        const listed = shadows.map((r) => `${r.skill} ${fmt(r.score)}`).join(" · ")
        console.log(`      ⓘ explicit-invoke scores higher: ${listed} — overlap, not routable`)
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
      if (mine === 0 && owner.score === 0) {
        // The positives above refuse to read a ranking out of a prompt that discriminates nothing;
        // a negative deserves the same. `0 < 0` is false, so without this the prompt fails the run
        // as a theft — pointing the author at a description that is not the problem.
        tally.negBlank++
        console.log(`  ✗ no signal    "${negative.prompt}"`)
        console.log(
          `      └ neither ${entry.skill} nor ${negative.owner} scores — nothing asserted`,
        )
        continue
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

type Totals = {
  rank1: number
  positives: number
  negOk: number
  negatives: number
  negBlank: number
  pct: number
}

function summarise(tallies: Tally[], corpusSize: number, scored: number): Totals {
  const width = Math.max(...tallies.map((t) => t.skill.length), 5)
  console.log(`\n${"skill".padEnd(width)}  rank-1   yields   shadowed`)
  console.log(`${"-".repeat(width)}  -------  -------  --------`)

  const totals: Totals = { rank1: 0, positives: 0, negOk: 0, negatives: 0, negBlank: 0, pct: 0 }
  for (const tally of tallies) {
    totals.rank1 += tally.rank1
    totals.positives += tally.positives
    totals.negOk += tally.negOk
    totals.negatives += tally.negatives
    totals.negBlank += tally.negBlank
    const a = `${tally.rank1}/${tally.positives}`
    const b = `${tally.negOk}/${tally.negatives}`
    console.log(`${tally.skill.padEnd(width)}  ${a.padEnd(7)}  ${b.padEnd(7)}  ${tally.shadowed}`)
  }

  totals.pct = totals.positives === 0 ? 0 : Math.round((totals.rank1 / totals.positives) * 100)
  console.log(`${"-".repeat(width)}  -------  -------  --------`)
  const head = `${totals.rank1}/${totals.positives}`
  console.log(`${"TOTAL".padEnd(width)}  ${head.padEnd(7)}  ${totals.negOk}/${totals.negatives}`)
  console.log(`\nrank-1 ${totals.pct}% · ${scored} of ${corpusSize} skills have case files`)
  return totals
}

/**
 * Prints the closest pairs whether or not they breach anything. A bare "none above 0.5" tells you
 * nothing about how much headroom is left, and headroom is the thing worth watching: the number
 * creeping from 0.2 to 0.4 across a few commits is the early warning the thresholds only catch late.
 */
function reportCollisions(index: Index, show: number): number {
  const found = findCollisions(index)
  const breaching = found.filter((pair) => pair.score >= COLLIDE_WARN)
  const listed = breaching.length > 0 ? breaching : found.slice(0, show)

  console.log(
    `\ndescription pairs, closest first (warn ≥${COLLIDE_WARN}, error ≥${COLLIDE_ERROR}):`,
  )
  let errors = 0
  for (const pair of listed) {
    let mark = "  ok  "
    if (pair.score >= COLLIDE_ERROR) {
      mark = "✗ error"
      errors++
    } else if (pair.score >= COLLIDE_WARN) {
      mark = "· warn "
    }
    console.log(`  ${mark}  ${fmt(pair.score)}  ${pair.a} ↔ ${pair.b}`)
  }
  if (breaching.length === 0) {
    console.log(`  nothing at or above ${COLLIDE_WARN} — ${found.length} pairs scanned`)
  }
  return errors
}

// --- explain -----------------------------------------------------------------

const FATE_LABEL: Record<Fate, string> = {
  kept: "kept",
  short: "dropped — shorter than 2 characters",
  stopword: "dropped — stopword",
  "stem-stopword": "dropped — stems to a stopword",
}

/**
 * One prompt, scored out loud. It answers the question the pass/fail report cannot: *why* this
 * ranking — which words survived tokenizing, which surviving stems carry any signal at all, and how
 * much each one contributed to each skill's score.
 *
 * It calls the same tokenize / classify / weigh / cosine / rank the eval calls and does no arithmetic
 * of its own beyond multiplying the two weights it prints. An explanation that computed the score a
 * second way would eventually explain something the eval no longer does.
 */
function explain(index: Index, prompt: string, top: number): void {
  const classified = splitWords(prompt)
    .filter((word) => word !== "")
    .map(classify)

  console.log(`\nprompt: "${prompt}"`)

  if (classified.length === 0) {
    console.log("\n  no words — nothing to score")
    return
  }

  const wordWidth = Math.max(...classified.map((entry) => entry.word.length), 4)
  const stemWidth = Math.max(...classified.map((entry) => entry.stem.length), 4)
  console.log(`\n${"word".padEnd(wordWidth)}  ${"stem".padEnd(stemWidth)}  fate`)
  for (const entry of classified) {
    const shown = entry.stem === "" ? "—" : entry.stem
    console.log(
      `${entry.word.padEnd(wordWidth)}  ${shown.padEnd(stemWidth)}  ${FATE_LABEL[entry.fate]}`,
    )
  }

  const tokens = classified.filter((entry) => entry.fate === "kept").map((entry) => entry.stem)
  const query = weigh(tokens, index.idf)

  // First-appearance order, not sorted: reading it beside the prompt is the point.
  const counts = new Map<string, number>()
  for (const token of tokens) counts.set(token, (counts.get(token) ?? 0) + 1)

  const termWidth = Math.max(...[...counts.keys()].map((term) => term.length), 4)
  console.log(
    `\n${"term".padEnd(termWidth)}  count  idf     weight  ` +
      `(idf = log(${index.names.length}/df), weight is L2-normalised)`,
  )
  for (const [term, count] of counts) {
    const idf = index.idf.get(term)
    const weight = query.get(term)
    let tail: string
    if (idf === undefined) tail = "—       —       in no description — out of vocabulary"
    // df = N, so idf is 0 and the term drops out. No term in this corpus reaches it, which is why
    // this branch has never printed — kept because it is the one case a 0 weight is not a bug.
    else if (weight === undefined) tail = `${fmt(idf)}   —       in every description — idf 0`
    else tail = `${fmt(idf)}   ${fmt(weight)}`
    console.log(`${term.padEnd(termWidth)}  ${String(count).padEnd(5)}  ${tail}`)
  }

  if (query.size === 0) {
    console.log(
      "\nno term carries signal — every skill scores 0 and the ranking would be alphabetical",
    )
    return
  }

  console.log(
    `\ntop ${top} of ${index.names.length} skills — contribution = query weight × skill weight:`,
  )
  const ranked = rank(index, prompt)
    .filter((entry) => entry.score > 0)
    .slice(0, top)
  if (ranked.length === 0) {
    console.log("  nothing scored above 0")
    return
  }
  for (let i = 0; i < ranked.length; i++) {
    const entry = ranked[i]
    const marker = index.explicit.has(entry.skill) ? "  (explicit-invoke, never ranked)" : ""
    console.log(`\n  ${i + 1}  ${entry.skill}  ${fmt(entry.score)}${marker}`)
    const vector = index.vectors.get(entry.skill) ?? new Map<string, number>()
    const parts: { term: string; weight: number; doc: number; product: number }[] = []
    for (const [term, weight] of query) {
      const doc = vector.get(term)
      if (doc === undefined) continue
      parts.push({ term, weight, doc, product: weight * doc })
    }
    parts.sort((a, b) => b.product - a.product || a.term.localeCompare(b.term))
    if (parts.length === 0) {
      console.log("       no shared term")
      continue
    }
    for (const part of parts) {
      console.log(
        `       ${part.term.padEnd(termWidth)}  ${fmt(part.weight)} × ${fmt(part.doc)} = ${fmt(part.product)}`,
      )
    }
  }
}

// --- entry point -------------------------------------------------------------

const USAGE =
  "usage: node evals/routing.ts [--top <n>] [--min-rank1 <percent>] [--explain <prompt>] [skill...]"

function main(argv: string[]): void {
  let top = 3
  let minRank1: number | null = null
  let explainPrompt: string | null = null
  const filter: string[] = []

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]
    if (arg === "--top") {
      const value = Number(argv[++i])
      if (!Number.isInteger(value) || value < 1) fail("--top needs a positive integer")
      top = value
    } else if (arg === "--min-rank1") {
      const value = Number(argv[++i])
      if (!Number.isFinite(value) || value < 0 || value > 100) {
        fail("--min-rank1 needs a percentage between 0 and 100")
      }
      minRank1 = value
    } else if (arg === "--explain") {
      const value = argv[++i]
      if (value === undefined || value.trim() === "") fail("--explain needs a prompt")
      explainPrompt = value
    } else if (arg === "-h" || arg === "--help") {
      console.log(USAGE)
      return
    } else if (arg.startsWith("-")) {
      fail(`unknown flag ${arg}\n${USAGE}`)
    } else {
      filter.push(arg)
    }
  }

  const docs = buildCorpus()
  const index = buildIndex(docs)

  if (explainPrompt !== null) {
    // The whole corpus, always: idf is a property of every description, so narrowing to a filter
    // would print weights the eval never uses.
    if (filter.length > 0) fail("--explain scores against the whole corpus — drop the skill filter")
    console.log(`corpus: ${docs.length} skills`)
    explain(index, explainPrompt, top)
    return
  }

  const cases = loadCases(filter)

  const explicit = [...index.explicit]
  console.log(`corpus: ${docs.length} skills · ${explicit.length} explicit-invoke, in the`)
  console.log(`        collision scan but never ranked against: ${explicit.join(", ")}`)

  const tallies = report(cases, index, top)
  const totals = summarise(tallies, docs.length, cases.length)
  // Always the whole corpus, even when `skill...` narrowed the prompts: a collision is a property
  // of the descriptions, and scanning only the filtered pairs would hide the one you did not name.
  const collisionErrors = reportCollisions(index, top)

  const problems: string[] = []
  const steals = totals.negatives - totals.negOk - totals.negBlank
  if (steals > 0) {
    problems.push(`${steals} negative prompt(s) rank their own skill at or above the named owner`)
  }
  if (totals.negBlank > 0) {
    problems.push(
      `${totals.negBlank} negative prompt(s) score zero on both sides — they assert nothing`,
    )
  }
  if (collisionErrors > 0) {
    problems.push(`${collisionErrors} description pair(s) at or above ${COLLIDE_ERROR} cosine`)
  }
  if (minRank1 !== null && totals.pct < minRank1) {
    problems.push(`rank-1 ${totals.pct}% is below the --min-rank1 floor of ${minRank1}%`)
  }

  console.log()
  if (problems.length === 0) {
    console.log("routing eval passed.")
    return
  }
  for (const problem of problems) console.error(`::error::${problem}`)
  console.error("routing eval FAILED.")
  process.exit(1)
}

main(process.argv.slice(2))
