export class CsvRenderer {
    render(ast, rows) {
        if (ast.format === "json") {
            // JSON 포맷이지만 CSV 렌더러가 호출될 수 있으니 방어적으로 Buffer 반환
            const buf = Buffer.from(JSON.stringify(rows), "utf8");
            return buf;
        }
        const header = (ast.columns ?? []).join(",");
        const lines = rows.map(r => (ast.columns ?? []).map(c => String(r?.[c] ?? "")).join(","));
        const text = [header, ...lines].join("\n");
        return text;
    }
}
