function isArrayOfObjects(v) {
    return Array.isArray(v) && v.length > 0 && typeof v[0] === "object" && v[0] !== null;
}
/**
 * ✅ 규칙(결정적):
 * - DSL JSON에서 inline dataset 키는 아래 순서로만 인정
 *   rows > data > items > records > list > values > entries > results > result
 * - 각 키는 "객체배열"일 때만 채택
 * - 그 외 루트 폴백/추측 금지(비결정성 제거)
 */
function deriveInlineDatasets(dsl, ast, base) {
    if (base && Object.keys(base).length > 0)
        return base;
    const allowedKeys = ["rows", "data", "items", "records", "list", "values", "entries", "results", "result"];
    try {
        const obj = JSON.parse(dsl);
        for (const k of allowedKeys) {
            const v = obj?.[k];
            if (isArrayOfObjects(v))
                return { [ast.from]: v };
        }
    }
    catch { /* not JSON */ }
    return base;
}
export class ReportService {
    parser;
    query;
    renderer;
    constructor(parser, query, renderer) {
        this.parser = parser;
        this.query = query;
        this.renderer = renderer;
    }
    async run(dsl, datasets = {}) {
        const ast0 = await this.parser.parse(dsl);
        const ast = { ...ast0, format: ast0.format ?? "csv" };
        const ds = deriveInlineDatasets(dsl, ast, datasets);
        const rows = await this.query.fetch(ast, ds);
        // 열 보정: 없으면 rows[0] 키 기반
        const inferredCols = Array.isArray(ast.columns) && ast.columns.length > 0
            ? ast.columns
            : (Array.isArray(rows) && rows.length > 0 && rows[0] && typeof rows[0] === "object"
                ? Object.keys(rows[0])
                : []);
        const safeAst = { ...ast, columns: inferredCols };
        // RenderPort 계약 호출( ast, rows )
        // 구현체가 string|Buffer를 ReportResult로 캐스팅 → 테스트 기대 충족
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return this.renderer.render(safeAst, rows);
    }
}
