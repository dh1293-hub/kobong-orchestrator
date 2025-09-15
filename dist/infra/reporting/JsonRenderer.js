export class JsonRenderer {
    render(ast, rows) {
        const cols = Array.isArray(ast?.columns) && ast.columns.length > 0
            ? ast.columns
            : (Array.isArray(rows) && rows.length > 0 && rows[0] && typeof rows[0] === "object"
                ? Object.keys(rows[0])
                : []);
        const projected = cols.length > 0
            ? rows.map((r) => {
                const o = {};
                for (const c of cols)
                    o[c] = r?.[c];
                return o;
            })
            : rows;
        const buf = Buffer.from(JSON.stringify(projected), "utf8");
        return buf;
    }
}
