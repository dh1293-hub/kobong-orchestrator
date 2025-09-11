/** tests/unit/reporting/report.service.spec.ts */
import { describe, it, expect } from "vitest";
import { ReportService } from "../../../app/reporting/ReportService";
import { ParserAdapter } from "../../../infra/reporting/ParserAdapter";
import { QueryStub } from "../../../infra/reporting/QueryStub";
import { CsvRenderer } from "../../../infra/reporting/CsvRenderer";
import { JsonRenderer } from "../../../infra/reporting/JsonRenderer";

describe("ReportService (scaffold)", () => {
  const parser = new ParserAdapter();
  const query = new QueryStub();

  it("runs CSV pipeline (placeholder DSL=JSON)", async () => {
    const svc = new ReportService(parser, query, new CsvRenderer());
    const dsl = JSON.stringify({
      source: "demo",
      fields: [{ name: "id" }, { name: "name" }, { name: "amount" }],
      format: "csv"
    });
    const out = await svc.run(dsl);
    expect(typeof out).toBe("string");
    expect((out as string).split("\n")[0]).toBe("id,name,amount");
  });

  it("runs JSON pipeline (placeholder DSL=JSON)", async () => {
    const svc = new ReportService(parser, query, new JsonRenderer());
    const dsl = JSON.stringify({
      source: "demo",
      fields: [{ name: "id" }, { name: "name" }, { name: "amount" }],
      format: "json"
    });
    const out = await svc.run(dsl);
    expect(Buffer.isBuffer(out)).toBeTruthy();
    const arr = JSON.parse((out as Buffer).toString("utf8"));
    expect(arr.length).toBe(2);
  });
});
