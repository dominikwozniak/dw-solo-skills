<!-- LEDE — one paragraph, at most 4 sentences. Why now: the problem this change answers.
     Present tense, as if the branch had always looked this way. No file list, no history, no
     "previously / now" — what changed since the last review goes in the chat.
     e.g. "`dw-land` composes a PR body from scratch, so no two PRs read alike. This template is
     the shape it fills instead." -->

## What changes

<!-- One to four bullets, one per unit of work, at most two lines each. Lead with the `path` or
     the **skill**, then what it now does. Nothing the diff already says, nothing merely planned.
     e.g.
     - **dw-land** — fills this template instead of composing a body.
     - `templates/PULL_REQUEST_TEMPLATE.md` — a symlink to the `.github/` copy, so there is one
       file to edit. -->

## How it flows

<!-- OPTIONAL — one small mermaid diagram, ten nodes at most, and only when the change moves a
     flow, a sequence or a state machine AND the picture beats the prose. Otherwise delete this
     section, heading included. No prose around it; the diagram stands alone. A fenced `mermaid`
     block holding something like:
        flowchart LR
          land[dw-land] --> tpl[read template] --> pr[gh pr create] -->

## Test plan

<!-- What was RUN and what it said — the command and its verdict, never an intention. A bug fix
     names its regression test. Whatever is left to do by hand goes last, marked "by hand".
     e.g.
     - `pnpm validate:artifacts` — pass
     - `pnpm eval:routing` — 24/24
     - by hand: opened a PR from a scratch branch, template prefilled -->

## Risk

<!-- One line: what breaks if this is wrong, and the way back. Always filled — "None, docs only."
     is a real answer and the usual one. -->
