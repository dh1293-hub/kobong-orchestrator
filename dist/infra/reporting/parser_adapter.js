import { parse as parseV04 } from "../../domain/dsl/v0_4/parser";
/** ParserAdapter — DSL v0.4 전용 어댑터 */
export class ParserAdapter {
    parse(dsl) { return parseV04(dsl); }
}
