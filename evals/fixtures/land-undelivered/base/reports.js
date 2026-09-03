export function formatRows(rows) {
  return rows.map((r) => r.join(",")).join("\n")
}
