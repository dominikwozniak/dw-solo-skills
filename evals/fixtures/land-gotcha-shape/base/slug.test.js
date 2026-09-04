import { test } from "node:test"
import assert from "node:assert/strict"
import { slugify } from "./slug.js"

test("lowercases and joins words with a dash", () => {
  assert.equal(slugify("Hello World"), "hello-world")
})

test("trims leading and trailing separators", () => {
  assert.equal(slugify("  Hello!  "), "hello")
})
