import { describe, it, expect } from "vitest";
import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

function runCase(headerLine: string, tag: string) {
  const tmp = mkdtempSync(join(tmpdir(), "acl-notes-"));
  const changelog = [
    "# Changelog",
    "",
    headerLine,
    "",
    "- feat: A",
    "- fix: B",
  ].join("\n");
  writeFileSync(join(tmp, "CHANGELOG.md"), changelog, "utf8");

  const script = join(process.cwd(), "scripts", "acl", "release-notes.mjs");
  const out = join(tmp, "notes.md");

  // Run ESM script with cwd=tmp
  execFileSync(process.execPath, [script, `--tag=${tag}`, `--out=${out}`], { cwd: tmp });

  const text = readFileSync(out, "utf8").replace(/\r/g, "");
  return text;
}

describe("ACL release-notes adapter (contract)", () => {
  it("## [0.0.1] (date) 형태를 추출한다", () => {
    const res = runCase("## [0.0.1] (2025-09-11)", "v0.0.1");
    expect(res).toContain("# v0.0.1");
    expect(res).toContain("feat: A");
    expect(res).toContain("fix: B");
  });

  it("### [0.0.2] 형태를 추출한다", () => {
    const res = runCase("### [0.0.2]", "v0.0.2");
    expect(res).toContain("# v0.0.2");
    expect(res).toContain("feat: A");
  });

  it("#### 0.0.3 (괄호 없음) 형태를 추출한다", () => {
    const res = runCase("#### 0.0.3", "v0.0.3");
    expect(res).toContain("# v0.0.3");
    expect(res).toContain("fix: B");
  });
});