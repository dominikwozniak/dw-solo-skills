import { test } from "node:test"
import assert from "node:assert/strict"

import { toCsv } from "./csv.js"

test("plain fields join with commas", () => {
  assert.equal(toCsv([["a", "b"]]), "a,b")
})
