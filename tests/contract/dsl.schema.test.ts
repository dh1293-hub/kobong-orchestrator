import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import Ajv2020 from "ajv/dist/2020";

describe("Contract: Action DSL v0.3 schema", () => {
  it("accepts a minimal valid plan", () => {
    const raw = readFileSync(resolve("tests/schemas/dsl.v0_3.schema.json"), "utf8").replace(/^\uFEFF/, "");
    const schema = JSON.parse(raw);

    const ajv = new Ajv2020({ strict: false });
    const validate = ajv.compile(schema);

    const plan = [
      {
        step: 10,
        explain: "send prompt and wait",
        actions: [
          { LOCATE: { role: "ai1", by: "text", query: ["채팅 입력","Send a message"], timeout_ms: 5000 } },
          { FOCUS: { target: "@LOCATE" } },
          { PASTE: { text: "Hello" } },
          { PRESS: { keys: "Enter" } },
          { WAIT: 1200 },
          { SNAPSHOT: { label: "ai1_after_send" } },
          { VERIFY: { text_contains_any: ["Sent","응답 중…"] } }
        ]
      }
    ];

    const ok = validate(plan);
    expect(ok, JSON.stringify(validate.errors)).toBe(true);
  });
});
