import { test } from "node:test"
import assert from "node:assert/strict"

import { retry } from "./retry.js"

test("retry returns the first success", async () => {
  let calls = 0
  const value = await retry(async () => {
    calls++
    if (calls < 2) throw new Error("flaky")
    return "ok"
  })
  assert.equal(value, "ok")
  assert.equal(calls, 2)
})
