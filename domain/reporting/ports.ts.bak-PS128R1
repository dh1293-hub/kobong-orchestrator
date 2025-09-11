/* eslint-disable @typescript-eslint/no-explicit-any */ // TODO(PS-12.6): type properly
/**
 * Ports contract (converged) — step3
 * - ReportEnginePort: generate(req) 사용
 * - ReportRequest: title/columns/rows 포함
 * - ParsePort: 동기 반환(ReportSpec) — app/reporting/ReportService.ts와 일치
 */
export type PortContext = { traceId?: string; timeoutMs?: number; locale?: string };

export type ReportSpec = { source: any; fields: any; format: any };

export interface ParsePort {
  parse(input: unknown, ctx?: PortContext): ReportSpec;
}

export type ReportRequest = {
  title: string;
  columns: string[];
  rows: Array<Record<string, unknown>>;
};

export type ReportMeta   = { title?: string; rows?: number };
export type ReportResult = { mime: string; content: string; meta?: ReportMeta };

export interface ReportEnginePort {
  generate(req: ReportRequest, ctx?: PortContext): Promise<ReportResult>;
}

/* 유지용(기존 호출자 호환) */
export interface QueryPort  { run(input: unknown, ctx?: PortContext): Promise<any>; }
export interface RenderPort { render(input: unknown, options?: any, ctx?: PortContext): Promise<string | Buffer>; }


