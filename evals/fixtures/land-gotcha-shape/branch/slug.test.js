import { test } from "node:test"
import assert from "node:assert/strict"
import { slugify } from "./slug.js"

test("lowercases and joins words with a dash", () => {
  assert.equal(slugify("Hello World"), "hello-world")
})

test("trims leading and trailing separators", () => {
  assert.equal(slugify("  Hello!  "), "hello")
})

test("suffixes a collision with the first free number", () => {
  assert.equal(slugify("Hello World", new Set(["hello-world"])), "hello-world-2")
})

test("skips a suffix that is itself taken", () => {
  assert.equal(slugify("Hello World", new Set(["hello-world", "hello-world-2"])), "hello-world-3")
})
