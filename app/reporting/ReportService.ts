import type { ParsePort, QueryPort, RenderPort, DslAst, Datasets } from "../../domain/reporting/ports";

function isArrayOfObjects(v: unknown): v is Array<Record<string, unknown>> {
  return Array.isArray(v) && v.length > 0 && typeof v[0] === "object" && v[0] !== null;
}

/**
 * ✅ 규칙(결정적):
 * - DSL JSON에서 inline dataset 키는 아래 순서로만 인정
 *   rows > data > items > records > list > values > entries > results > result
 * - 각 키는 "객체배열"일 때만 채택
 * - 그 외 루트 폴백/추측 금지(비결정성 제거)
 */
function deriveInlineDatasets(dsl: string, ast: DslAst, base: Datasets): Datasets {
  if (base && Object.keys(base as object).length > 0) return base;
  const allowedKeys = ["rows","data","items","records","list","values","entries","results","result"] as const;
  try {
    const obj: any = JSON.parse(dsl);
    for (const k of allowedKeys) {
      const v = obj?.[k];
      if (isArrayOfObjects(v)) return { [ast.from]: v } as Datasets;
    }
  } catch { /* not JSON */ }
  return base;
}

export class ReportService {
  constructor(
    private readonly parser: ParsePort,
    private readonly query: QueryPort,
    private readonly renderer: RenderPort
  ) {}

  async run(dsl: string, datasets: Datasets = {} as Datasets) {
    const ast0 = await this.parser.parse(dsl) as DslAst;
    const ast: DslAst = { ...ast0, format: (ast0 as any).format ?? "csv" };

    const ds = deriveInlineDatasets(dsl, ast, datasets);
    const rows = await this.query.fetch(ast, ds);

    // 열 보정: 없으면 rows[0] 키 기반
    const inferredCols =
      Array.isArray((ast as any).columns) && (ast as any).columns.length > 0
        ? (ast as any).columns
        : (Array.isArray(rows) && rows.length > 0 && rows[0] && typeof rows[0] === "object"
            ? Object.keys(rows[0] as Record<string, unknown>)
            : []);
    const safeAst: DslAst = { ...ast, columns: inferredCols };

    // RenderPort 계약 호출( ast, rows )
    // 구현체가 string|Buffer를 ReportResult로 캐스팅 → 테스트 기대 충족
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return (this.renderer as any).render(safeAst, rows);
  }
}
