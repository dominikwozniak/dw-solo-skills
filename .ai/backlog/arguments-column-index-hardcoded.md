---
created: 2026-08-02
source: argument-hint-parity
---

# `validate-docs.sh` check 5 hardcodes Arguments as the 4th pipe field

`awk -F'|' '{print $4}'` assumes every task-router table is Skill | Task | Arguments | What you get.
All four agree today, but a fifth table or a reordered column would make the check grade the wrong
cell and pass — the silent-green failure it exists to prevent. Derive the index from the header row
instead; roughly three lines. Detail: `.ai/archive/argument-hint-parity`.
