import type { RenderPort, DslAst, Rows, ReportResult } from "../../domain/reporting/ports";

export class MemoryReportEngine implements RenderPort {
  render(ast: DslAst, rows: Rows): ReportResult {
    const header = ast.columns.join(",");
    const csvLines = rows.map((row: Record<string, unknown>) =>
      ast.columns.map((c: string) => csvCell(row[c])).join(",")
    );
    const csv = [header, ...csvLines].join("\n");
    return {
      title: `report:${ast.from}`,
      rows: rows.length,
      columns: ast.columns.length,
      buffer: csv
    };
  }
}

function csvCell(v: unknown): string {
  if (v === null || v === undefined) return "";
  const s = String(v);
  const needsQuote = /[",\n]/.test(s);
  const escaped = s.replace(/"/g, '""');
  return needsQuote ? `"${escaped}"` : s;
}
