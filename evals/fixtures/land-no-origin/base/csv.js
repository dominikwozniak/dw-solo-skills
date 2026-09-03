export function toCsv(rows) {
  return rows.map((row) => row.join(",")).join("\n")
}
