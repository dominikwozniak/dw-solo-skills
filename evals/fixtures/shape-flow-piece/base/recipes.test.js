import assert from "node:assert/strict"
import { test } from "node:test"
import { listRecipes } from "./recipes.js"

test("listRecipes returns every recipe with an id and a name", () => {
  const recipes = listRecipes()
  assert.equal(recipes.length, 3)
  for (const recipe of recipes) {
    assert.equal(typeof recipe.id, "number")
    assert.equal(typeof recipe.name, "string")
  }
})
