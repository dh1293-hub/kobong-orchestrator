import type { DslAst, Rows, RenderPort, ReportResult } from "../../domain/reporting/ports";

export class JsonRenderer implements RenderPort {
  render(ast: DslAst, rows: Rows): ReportResult {
    const cols =
      Array.isArray((ast as any)?.columns) && (ast as any).columns.length > 0
        ? (ast as any).columns as string[]
        : (Array.isArray(rows) && rows.length > 0 && rows[0] && typeof rows[0] === "object"
            ? Object.keys(rows[0] as Record<string, unknown>)
            : []);

    const projected =
      cols.length > 0
        ? rows.map((r) => {
            const o: Record<string, unknown> = {};
            for (const c of cols) o[c] = (r as any)?.[c];
            return o;
          })
        : rows;

    const buf = Buffer.from(JSON.stringify(projected), "utf8");
    return buf as unknown as ReportResult;
  }
}
