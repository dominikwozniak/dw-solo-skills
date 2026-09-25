import { readFileSync } from "node:fs"

const RECIPES = new URL("./data/recipes.json", import.meta.url)

export function listRecipes() {
  return JSON.parse(readFileSync(RECIPES, "utf8"))
}
