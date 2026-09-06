import { sendEmail } from "./notify.js"

export function ping() {
  return "pong"
}

export async function welcome(user) {
  return sendEmail(user.email, "Welcome", `Hi ${user.name}`)
}
