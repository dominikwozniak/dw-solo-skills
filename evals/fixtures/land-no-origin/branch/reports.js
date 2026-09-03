export function formatRows(rows) {
  return rows.map((r) => r.join(",")).join("\n")
}

export function toCsv(rows) {
  return formatRows(rows)
}

export function onExportClick(table) {
  const blob = new Blob([toCsv(table.rows)], { type: "text/csv" })
  return URL.createObjectURL(blob)
}
