export class MemoryReportEngine {
    render(ast, rows) {
        const header = ast.columns.join(",");
        const csvLines = rows.map((row) => ast.columns.map((c) => csvCell(row[c])).join(","));
        const csv = [header, ...csvLines].join("\n");
        return {
            title: `report:${ast.from}`,
            rows: rows.length,
            columns: ast.columns.length,
            buffer: csv
        };
    }
}
function csvCell(v) {
    if (v === null || v === undefined)
        return "";
    const s = String(v);
    const needsQuote = /[",\n]/.test(s);
    const escaped = s.replace(/"/g, '""');
    return needsQuote ? `"${escaped}"` : s;
}
