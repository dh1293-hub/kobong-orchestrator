import { ReportService } from "../../app/reporting/ReportService";
import { ParserAdapter } from "../../infra/reporting/ParserAdapter";
import { QueryStub } from "../../infra/reporting/QueryStub";
import { CsvRenderer } from "../../infra/reporting/CsvRenderer";
import type { Datasets } from "../../domain/reporting/ports";

export async function runOnce(dsl: string, datasets: Datasets = {} as Datasets) {
  const svc = new ReportService(new ParserAdapter(), new QueryStub(), new CsvRenderer());
  return svc.run(dsl, datasets); // string | Buffer
}
export default runOnce;
