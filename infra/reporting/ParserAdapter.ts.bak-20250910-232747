/** infra/reporting/ParserAdapter.ts */
import type { ParsePort } from "../../domain/reporting/ports";
import { parseFromDsl } from "../../domain/dsl/parser";

export class ParserAdapter implements ParsePort {
  parse(dsl: string) { return parseFromDsl(dsl); }
}
