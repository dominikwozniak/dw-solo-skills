const NEEDS_QUOTING = /[",\n]/

function quote(field) {
  const text = String(field)
  if (!NEEDS_QUOTING.test(text)) return text
  return `"${text.replace(/"/g, '""')}"`
}

export function toCsv(rows) {
  return rows.map((row) => row.map(quote).join(",")).join("\n")
}
