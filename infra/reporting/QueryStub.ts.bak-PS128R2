/* eslint-disable @typescript-eslint/no-unused-vars */ // TODO(PS-12.6): delete _spec or use it
/** infra/reporting/QueryStub.ts */
import type { QueryPort } from "../../domain/reporting/ports";
import type { ReportSpec } from "../../domain/reporting/types";

/** 임시 쿼리: source/filters 무시하고 데모 데이터 반환 */
export class QueryStub implements QueryPort {
  async run(_spec: ReportSpec): Promise<Record<string, unknown>[]> {
    return [
      { id: 1, name: "Alice", amount: 1200 },
      { id: 2, name: "Bob",   amount:  950 },
    ];
  }
}




