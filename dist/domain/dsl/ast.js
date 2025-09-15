/** 임시 파서: 현재는 전체를 ReportSpec JSON으로만 허용(placeholder) */
export function parseToSpec(input) {
    input = input.trim();
    // 1단계: JSON 직통 파스(DSL 완성 전 임시)
    try {
        const spec = JSON.parse(input);
        return spec;
    }
    catch {
        throw new Error("DSL parser placeholder: JSON 형태의 ReportSpec 문자열만 허용합니다.");
    }
}
