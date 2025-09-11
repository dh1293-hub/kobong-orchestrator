/** domain/reporting/ports.ts */
import type { ReportSpec } from "./types";

export interface QueryPort {
  /** ReportSpec을 받아 원시 레코드(plain objects) 배열을 돌려줍니다. */
  run(spec: ReportSpec): Promise<Record<string, unknown>[]>;
}

export interface RenderPort {
  /** 레코드 배열을 지정 포맷(csv/json 등)으로 직렬화 */
  render(records: Record<string, unknown>[], spec: ReportSpec): Promise<Buffer | string>;
}

export interface ParsePort {
  /** DSL 문자열을 ReportSpec으로 파싱 */
  parse(dsl: string): ReportSpec;
}


