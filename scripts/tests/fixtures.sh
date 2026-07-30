#!/usr/bin/env bash
# Document builders for validate-ai-artifacts.test.sh — SOURCED, not executed.
# Each function emits one canonical .ai/ artifact (SPEC / PLAN / review) on stdout.
# The test derives malformed cases from these via one-line sed defects; only the two
# structural-shape defects (missing column, reordered step ids) get a dedicated builder.
# Tables use single spaces (the validator strips whitespace). bash 3.2 / macOS safe.

good_spec() {
  cat <<'EOF'
---
run: 20260101-x
ticket: ABC-123
status: ready
created: 2026-01-02
branch: feature-x
---

# Spec — fixture
EOF
}

spec_draft() {
  cat <<'EOF'
---
run: 20260101-draft
ticket: none
status: draft
created: 2026-01-01
branch: draft-run
---

# Spec — fixture
EOF
}

good_plan_done() {
  cat <<'EOF'
---
run: 20260101-x
spec: ./SPEC.md
status: done
---

# Plan — fixture

| Phase | Step | Title | Status | Commit |
| --- | --- | --- | --- | --- |
| 1 | 1.1 | slice | done | abc1234 |
EOF
}

good_plan_todo() {
  cat <<'EOF'
---
run: 20260101-x
spec: ./SPEC.md
status: todo
---

# Plan — fixture

| Phase | Step | Title | Status | Commit |
| --- | --- | --- | --- | --- |
| 1 | 1.1 | slice | todo |  |
| 1 | 1.2 | slice | todo |  |
EOF
}

good_review() {
  cat <<EOF
---
branch: $1
base: main
input: branch
created: 2026-01-04
sources: none
---

# Review — fixture
EOF
}

# Slices: the smallest well-formed graph — one free slice plus its INDEX. The graph's own
# invariants are pinned in slice-status.test.sh; these exist so the validator's run-level
# wiring (delegation, and the PLAN.md-xor-slices/ rule) can be tested.
good_slice_01() {
  cat <<'EOF'
---
slice: "01"
run: 20260101-x
title: fixture slice
status: ready
blocked_by: []
blocks: []
---

# 01 — fixture slice
EOF
}

good_slices_index() {
  cat <<'EOF'
---
run: 20260101-x
spec: ../SPEC.md
slices: 1
---

# Slices — fixture
EOF
}

# Structural-shape defects: explicit builders (a sed would only obscure them).
plan_bad_header() { # status table missing the Commit column
  cat <<'EOF'
---
run: 20260101-x
spec: ./SPEC.md
status: todo
---

# Plan — fixture

| Phase | Step | Title | Status |
| --- | --- | --- | --- |
| 1 | 1.1 | slice | todo |
EOF
}

plan_nonmonotonic() { # step ids out of order: 1.1, 1.3, 1.2
  cat <<'EOF'
---
run: 20260101-x
spec: ./SPEC.md
status: todo
---

# Plan — fixture

| Phase | Step | Title | Status | Commit |
| --- | --- | --- | --- | --- |
| 1 | 1.1 | slice | todo |  |
| 1 | 1.3 | slice | todo |  |
| 1 | 1.2 | slice | todo |  |
EOF
}
