export async function fetchOrder(id) {
  const response = await fetch(`https://orders.invalid/${id}`)
  return response.json()
}
