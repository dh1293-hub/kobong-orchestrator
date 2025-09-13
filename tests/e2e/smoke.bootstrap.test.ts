import { describe, it, expect } from "vitest";
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import Ajv2020 from "ajv/dist/2020";
import addFormats from "ajv-formats";

const CWD = process.cwd();
const ENTRY = resolve(CWD, "dist", "app", "bootstrap.js");
const LOG_FILE = resolve(CWD, "logs", "app.log");

describe("E2E-SMOKE: bootstrap entry", () => {
  it("runs dist/app/bootstrap.js -> ExitCode=0 and writes valid JSONL log", async () => {
    expect(existsSync(ENTRY)).toBe(true);

    const out = spawnSync(process.execPath, [ENTRY], {
      cwd: CWD,
      env: { ...process.env, NODE_ENV: "test" },
      stdio: "pipe",
      timeout: 10000
    });

    expect(out.status, `node exit status\n${out.stderr?.toString()}`).toBe(0);
    expect(existsSync(LOG_FILE)).toBe(true);

    const content = readFileSync(LOG_FILE, "utf8").trim();
    expect(content.length).toBeGreaterThan(0);

    const lastLine = content.split(/\r?\n/).at(-1)!;
// eslint-disable-next-line @typescript-eslint/no-explicit-any
    let parsed: any;
    try {
      parsed = JSON.parse(lastLine.replace(/^\uFEFF/, ""));
    } catch {
      throw new Error("Last log line is not valid JSON: " + lastLine);
    }

    const rawSchema = readFileSync(resolve(CWD, "tests/schemas/log_line.schema.json"), "utf8").replace(/^\uFEFF/, "");
    const schema = JSON.parse(rawSchema);

    const ajv = new Ajv2020({ strict: false });
    addFormats(ajv);

    const validate = ajv.compile(schema);
    const valid = validate(parsed);
    if (!valid) {
      throw new Error("Log schema validation failed: " + JSON.stringify(validate.errors, null, 2));
    }
  });
});

