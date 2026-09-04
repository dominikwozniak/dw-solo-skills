const NON_WORD = /[^a-z0-9]+/g

export function slugify(title) {
  return title.toLowerCase().replace(NON_WORD, "-").replace(/^-|-$/g, "")
}
