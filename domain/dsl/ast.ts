/** domain/dsl/ast.ts */
import type { ReportSpec } from "../reporting/types";

/** AST 최소 구조: 향후 nearley/ohm-js 등 교체 가능 */
export type DslDoc = { kind: "Report"; body: string };

/** 임시 파서: 현재는 전체를 ReportSpec JSON으로만 허용(placeholder) */
export function parseToSpec(input: string): ReportSpec {
  input = input.trim();
  // 1단계: JSON 직통 파스(DSL 완성 전 임시)
  try {
    const spec = JSON.parse(input) as ReportSpec;
    return spec;
  } catch {
    throw new Error("DSL parser placeholder: JSON 형태의 ReportSpec 문자열만 허용합니다.");
  }
}


