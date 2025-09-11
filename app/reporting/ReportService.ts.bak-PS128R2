/** app/reporting/ReportService.ts */
import type { ParsePort, QueryPort, RenderPort } from "../../domain/reporting/ports";
import type { ReportSpec } from "../../domain/reporting/types";

export class ReportService {
  constructor(
    private readonly parser: ParsePort,
    private readonly query: QueryPort,
    private readonly renderer: RenderPort,
  ) {}

  async run(dsl: string): Promise<Buffer | string> {
    const spec: ReportSpec = this.parser.parse(dsl);
    const rows = await this.query.run(spec);
    return this.renderer.render(rows, spec);
  }
}



