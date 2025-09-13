/** ===== Domain Contracts (Reporting) ===== */

export type Row = Record<string, unknown>;
export type Rows = Row[];
export type Datasets = Record<string, Rows>;

export interface DslAst {
  from: string;           // dataset key
  columns: string[];      // projection list
  format?: "csv" | "json";
}

/** ParsePort: DSL → AST */
export interface ParsePort {
  parse(dsl: string): Promise<DslAst> | DslAst;
}

/** QueryPort: AST + datasets → rows */
export interface QueryPort {
  fetch(ast: DslAst, datasets: Datasets): Promise<Rows> | Rows;
}

/** RenderPort: AST + rows → artifact/result */
export interface ReportResult {
  title: string;
  rows: number;
  columns: number;
  buffer?: string;        // inline artifact (csv/json string)
  artifactPath?: string;  // optional persisted path
}
export interface RenderPort {
  render(ast: DslAst, rows: Rows): Promise<ReportResult> | ReportResult;
}
