/* eslint-disable @typescript-eslint/no-explicit-any */ // TODO(PS-12.6): type properly
import type { ReportEnginePort, ReportResult } from "../../domain/reporting/ports";
import { parse } from "../../domain/dsl/v0_4/parser";

export class ReportService {
  constructor(private engine: ReportEnginePort) {}

  async run(dsl: string, datasets: Record<string, Record<string, unknown>[]>): Promise<ReportResult> {
    const ast = parse(dsl);
    const rows = datasets[ast.from] ?? [];
    const filtered = ast.where ? rows.filter(r => JSON.stringify(r).includes(ast.where!)) : rows;
    const projected = filtered.map((r) => {
      const o: Record<string, unknown> = {};
      for (const c of ast.columns) o[c] = (r as any)[c];
      return o;
    });
    return this.engine.generate({ title: `report:${ast.from}`, columns: ast.columns, rows: projected });
  }
}
