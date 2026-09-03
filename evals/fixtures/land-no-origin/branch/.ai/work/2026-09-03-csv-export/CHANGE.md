---
change: csv-export
branch: csv-export
created: 2026-09-03
status: building
---

# Change — the reports page exports CSV

## Goal

A user on the reports page clicks Export and gets a `.csv` of the rows currently shown. You know it
worked when clicking Export downloads a file whose rows match the table on screen.

## Tasks

- [x] 1. `formatRows` turns rows into CSV text.
- [x] 2. The Export button, and the download it triggers.
