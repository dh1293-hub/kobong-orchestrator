import { describe, it, expect } from "vitest";
import fs from "fs";

describe("contract smoke", () => {
  it("truthy check", () => {
    expect(true).toBe(true);
  });

  it("repo has package.json with name", () => {
    const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
    expect(pkg).toBeTruthy();
    expect(typeof pkg.name).toBe("string");
    expect(pkg.name.length).toBeGreaterThan(0);
  });
});