export async function retry(fn, attempts = 3) {
  let last
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn()
    } catch (error) {
      last = error
    }
  }
  throw last
}
