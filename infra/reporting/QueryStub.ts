import type { DslAst, Datasets, Rows, QueryPort } from "../../domain/reporting/ports";

function isArrayOfObjects(v: unknown): v is Array<Record<string, unknown>> {
  return Array.isArray(v) && v.length > 0 && typeof v[0] === "object" && v[0] !== null;
}

function coverageScore(cols: string[] | undefined, sample?: Record<string, unknown> | null): number {
  if (!cols || cols.length === 0) return 0;
  if (!sample || typeof sample !== "object") return 0;
  const keys = new Set(Object.keys(sample));
  let s = 0;
  for (const c of cols) if (keys.has(c)) s++;
  return s;
}

export class QueryStub implements QueryPort {
  async fetch(ast: DslAst, datasets: Datasets): Promise<Rows> {
    const anyDs = datasets as any;

    // 0) 정밀: from 키가 정확히 있고 객체배열이면 그대로
    if (isArrayOfObjects(anyDs?.[ast.from])) {
      return this.project(anyDs[ast.from], ast);
    }

    // 1) 후보 수집 (객체배열만)
    const candidates: Array<Array<Record<string, unknown>>> = [];
    if (isArrayOfObjects(anyDs)) candidates.push(anyDs); // datasets 자체가 배열인 경우
    if (anyDs && typeof anyDs === "object") {
      for (const v of Object.values(anyDs)) {
        if (isArrayOfObjects(v)) candidates.push(v);
      }
    }

    // 2) 열 적합도 최고 후보 선택(동점이면 먼저 나온 것)
    if (candidates.length > 0) {
      candidates.sort((a, b) => coverageScore(ast.columns, b[0]) - coverageScore(ast.columns, a[0]));
      return this.project(candidates[0], ast);
    }

    // 3) 최종 폴백: 1행 더미
    const row: Record<string, unknown> = {};
    for (const c of (ast.columns ?? [])) row[c] = `${ast.from}:${c}`;
    return [row];
  }

  private project(source: Array<Record<string, unknown>>, ast: DslAst): Rows {
    const cols = (ast.columns && ast.columns.length > 0)
      ? ast.columns
      : (source[0] && typeof source[0] === "object" ? Object.keys(source[0]) : []);
    return source.map((rec) => {
      const out: Record<string, unknown> = {};
      for (const c of cols) out[c] = (rec as any)?.[c];
      return out;
    });
  }
}
