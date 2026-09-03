export function formatRows(rows) {
  return rows.map((r) => r.join(",")).join("\n")
}

export function toCsv(rows) {
  return formatRows(rows)
}
