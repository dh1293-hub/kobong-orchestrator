import type { DslAst, Rows, RenderPort, ReportResult } from "../../domain/reporting/ports";

export class CsvRenderer implements RenderPort {
  render(ast: DslAst, rows: Rows): ReportResult {
    if (ast.format === "json") {
      // JSON 포맷이지만 CSV 렌더러가 호출될 수 있으니 방어적으로 Buffer 반환
      const buf = Buffer.from(JSON.stringify(rows), "utf8");
      return buf as unknown as ReportResult;
    }
    const header = (ast.columns ?? []).join(",");
    const lines = rows.map(r => (ast.columns ?? []).map(c => String((r as any)?.[c] ?? "")).join(","));
    const text = [header, ...lines].join("\n");
    return text as unknown as ReportResult;
  }
}
