export function slug(value) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
}

export function slugWithFallback(value, fallback) {
  const out = slug(value)
  return out === "" ? fallback : out
}
