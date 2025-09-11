import type { ReportEnginePort, ReportRequest, ReportResult } from "../../domain/reporting/ports";

export class MemoryReportEngine implements ReportEnginePort {
  async generate(req: ReportRequest): Promise<ReportResult> {
    const header = req.columns.join(",");
    const lines = req.rows.map((r: Record<string, unknown>) =>
// eslint-disable-next-line @typescript-eslint/no-explicit-any
      req.columns.map((c: string) => safeCsv((r as any)[c])).join(",")
    );
    const csv = [header, ...lines].join("\n");
    return { mime: "text/csv", content: csv, meta: { title: req.title, rows: req.rows.length } };
  }
}

function safeCsv(v: unknown): string {
  if (v === null || v === undefined) return "";
  const s = String(v);
  const needsQuote = /[",\n]/.test(s);
  return needsQuote ? `"${s.replace(/"/g, '""')}"` : s;
}
