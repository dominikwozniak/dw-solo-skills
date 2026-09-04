const NON_WORD = /[^a-z0-9]+/g

export function slugify(title, taken = new Set()) {
  const base = title.toLowerCase().replace(NON_WORD, "-").replace(/^-|-$/g, "")
  if (!taken.has(base)) return base
  let n = 2
  while (taken.has(`${base}-${n}`)) n += 1
  return `${base}-${n}`
}
