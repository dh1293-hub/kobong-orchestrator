import type { AST } from "../../domain/dsl/v0_4/types";
import type { ParsePort } from "../../domain/dsl/v0_4/ports";
import { parse as parseV04 } from "../../domain/dsl/v0_4/parser";
/** ParserAdapter — DSL v0.4 전용 어댑터 */
export class ParserAdapter implements ParsePort {
  parse(dsl: string): AST { return parseV04(dsl); }
}