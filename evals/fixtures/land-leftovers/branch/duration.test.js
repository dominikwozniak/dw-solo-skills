import assert from "node:assert/strict"
import { test } from "node:test"
import { formatDuration } from "./duration.js"

test("under a minute reads as seconds", () => {
  assert.equal(formatDuration(59), "59s")
})

test("hours and minutes appear only when non-zero", () => {
  assert.equal(formatDuration(3900), "1h 5m")
  assert.equal(formatDuration(3661), "1h 1m 1s")
})
