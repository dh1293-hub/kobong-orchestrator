/* eslint-disable @typescript-eslint/no-unused-vars */ // TODO(PS-12.6): delete _spec or use it
/** infra/reporting/CsvRenderer.ts */
import type { RenderPort } from "../../domain/reporting/ports";
import type { ReportSpec } from "../../domain/reporting/types";

export class CsvRenderer implements RenderPort {
  async render(records: Record<string, unknown>[], _spec: ReportSpec): Promise<string> {
    if (records.length === 0) return "";
    const headers = Array.from(new Set(records.flatMap(r => Object.keys(r))));
    const escape = (v: unknown) => {
      const s = String(v ?? "");
      return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
    };
    const lines = [
      headers.join(","),
// eslint-disable-next-line @typescript-eslint/no-explicit-any
      ...records.map(r => headers.map(h => escape((r as any)[h])).join(",")),
    ];
    return lines.join("\n");
  }
}





