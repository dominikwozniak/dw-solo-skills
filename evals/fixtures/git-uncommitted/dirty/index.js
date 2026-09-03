import { retry } from "./retry.js"

export async function fetchOrder(id) {
  return retry(async () => {
    const response = await fetch(`https://orders.invalid/${id}`)
    return response.json()
  })
}
