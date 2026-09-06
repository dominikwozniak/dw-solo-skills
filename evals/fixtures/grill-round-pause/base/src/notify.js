// The one send path this service has. Transactional only; no batching, no scheduling.
export async function sendEmail(to, subject, body) {
  if (!to) {
    throw new Error("sendEmail: recipient required")
  }
  return { to, subject, body, sentAt: new Date().toISOString() }
}
