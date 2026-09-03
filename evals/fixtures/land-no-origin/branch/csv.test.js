import { test } from "node:test"
import assert from "node:assert/strict"

import { toCsv } from "./csv.js"

test("plain fields join with commas", () => {
  assert.equal(toCsv([["a", "b"]]), "a,b")
})

test("a field holding a comma is quoted", () => {
  assert.equal(toCsv([["a,b", "c"]]), '"a,b",c')
})

test("an inner quote is doubled", () => {
  assert.equal(toCsv([['say "hi"']]), '"say ""hi"""')
})

test("a field holding a newline is quoted", () => {
  assert.equal(toCsv([["one\ntwo"]]), '"one\ntwo"')
})
