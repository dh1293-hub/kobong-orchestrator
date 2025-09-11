import type { AST } from "./types";
/** ParsePort — DSL v0.4 파서 계약 */
export interface ParsePort { parse(dsl: string): AST; }