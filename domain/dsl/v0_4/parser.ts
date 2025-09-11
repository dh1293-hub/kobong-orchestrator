import type { AST } from "./types";

/**
 * v0.4 초미니 파서:  SELECT a,b FROM name [WHERE expr]
 * - 공백 정규화, 대소문자 무관
 */
export function parse(dsl: string): AST {
  const src = dsl.trim().replace(/\s+/g, " ");
  const m = /^SELECT\s+([A-Za-z0-9_,\s]+)\s+FROM\s+([A-Za-z0-9_]+)(?:\s+WHERE\s+(.+))?$/i.exec(src);
  if (!m) throw new Error(`Invalid DSL v0.4: ${dsl}`);
  const cols = m[1].split(",").map(s => s.trim()).filter(Boolean);
  const from = m[2].trim();
  const where = m[3]?.trim();
  return { type: "Select", columns: cols, from, where };
}