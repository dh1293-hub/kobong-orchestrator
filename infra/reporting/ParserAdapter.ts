import type { DslAst, ParsePort } from "../../domain/reporting/ports";

function normalizeColumns(input: unknown, hint?: unknown): string[] {
  if (Array.isArray(input)) return input.map((v) => String(v));
  if (typeof input === "string") {
    const parts = input.split(/[,\s]+/).map(s => s.trim()).filter(Boolean);
    if (parts.length) return parts;
  }
  const rows = Array.isArray((hint as any)?.rows) ? (hint as any).rows
             : Array.isArray((hint as any)?.data) ? (hint as any).data
             : undefined;
  if (Array.isArray(rows) && rows.length > 0 && rows[0] && typeof rows[0] === "object") {
    return Object.keys(rows[0] as Record<string, unknown>);
  }
  return ["id", "name", "amount"];
}

export class ParserAdapter implements ParsePort {
  parse(dsl: string): DslAst | Promise<DslAst> {
    try {
      const obj: any = JSON.parse(dsl);
      const from = typeof obj.from === "string" ? obj.from : "dummy";
      const columns = normalizeColumns(obj.columns, obj);
      const format = obj.format === "json" ? "json" : "csv";
      return { from, columns, format };
    } catch {
      const from = (dsl.match(/from\s*[:=]\s*([A-Za-z0-9_]+)/i)?.[1]) ?? "dummy";
      const colsRaw = (dsl.match(/columns\s*[:=]\s*([^\r\n;]+)/i)?.[1]) ?? "";
      const columns = normalizeColumns(colsRaw);
      const fmt = (dsl.match(/format\s*[:=]\s*(json|csv)/i)?.[1]?.toLowerCase()) as "json"|"csv"|undefined;
      return { from, columns, format: fmt ?? "csv" };
    }
  }
}
