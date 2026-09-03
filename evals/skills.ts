// skills.ts — the skill corpus, shared by both eval tiers.
//
// `routing.ts` scores descriptions; `behaviour.ts` runs a skill and grades what it did. Both need
// the same three facts about every skill on disk: its description, whether the model is ever
// offered it, and where its directory is. This file is the single answer, extracted after the
// deleted `evals/trigger.ts` drifted from the case-file contract precisely because it kept its own
// looser copy of this logic.
//
// It raises `Error` rather than exiting, so each script keeps its own `fail()` and its own message
// prefix — the caller owns how a failure reads.
//
// Erasable syntax only: Node strips the types natively, so no enum, no parameter properties, no
// namespace. See `routing.ts`'s header for the version constraint.

import { existsSync, readdirSync, readFileSync } from "node:fs"
import { join } from "node:path"

export type SkillDoc = {
  name: string
  description: string
  /**
   * `disable-model-invocation: true`. Two very different consequences: the routing eval keeps such
   * a skill in the corpus but outside the ranked field, and the behaviour eval cannot reach it with
   * a prompt at all — the model is never offered it, so a case must invoke it by slash.
   */
  explicit: boolean
  /** What the routing eval scores. See `readSkillCorpus` for why it is name + description. */
  text: string
}

/**
 * The two-space-indented `description: >-` folded scalar every SKILL.md uses, plus plain and
 * quoted single-line values. Deliberately not a YAML parser: the frontmatter shape here is uniform
 * across every skill on disk, and a dependency for four keys would be the tail wagging the dog.
 */
export function parseFrontmatter(src: string): Map<string, string> {
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

/** Every `skills/<name>/SKILL.md` on disk, sorted by name. Throws on a malformed corpus. */
export function readSkillCorpus(skillsDir: string): SkillDoc[] {
  if (!existsSync(skillsDir)) throw new Error(`no skills/ directory at ${skillsDir}`)

  const docs: SkillDoc[] = []
  const names = readdirSync(skillsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort()

  for (const name of names) {
    const path = join(skillsDir, name, "SKILL.md")
    if (!existsSync(path)) continue
    const fm = parseFrontmatter(readFileSync(path, "utf8"))
    const description = fm.get("description") ?? ""
    if (description === "") {
      throw new Error(`skills/${name}/SKILL.md has no description in its frontmatter`)
    }
    const declared = fm.get("name")
    if (declared !== undefined && declared !== name) {
      throw new Error(
        `skills/${name}/SKILL.md declares name: ${declared} — directory and name must agree`,
      )
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
  if (docs.length === 0) throw new Error("found no skills to score against")
  return docs
}
