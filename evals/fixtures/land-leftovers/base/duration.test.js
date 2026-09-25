import assert from "node:assert/strict"
import { test } from "node:test"
import { formatDuration } from "./duration.js"

test("under a minute reads as seconds", () => {
  assert.equal(formatDuration(59), "59s")
})
