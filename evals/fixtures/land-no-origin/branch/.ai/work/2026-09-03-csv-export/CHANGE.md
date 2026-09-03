---
change: csv-export
branch: csv-export
created: 2026-09-03
status: building
---

# Change — `toCsv` escapes the fields that need it

## Goal

`toCsv(rows)` returns CSV that a spreadsheet reads back unchanged: a field containing a comma, a
double quote or a newline is wrapped in quotes, and an inner quote is doubled. You know it worked
when `pnpm test` passes with a case for each of those three fields.

## Tasks

- [x] 1. Quote a field containing a comma, a quote or a newline; double the inner quotes.
- [x] 2. A test for each of the three cases.
