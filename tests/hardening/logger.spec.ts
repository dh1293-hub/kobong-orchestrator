import { describe, expect, it } from "vitest";
import { maskPII } from "../../app/hardening";

describe("PII masking", () => {
  it("masks emails", () => {
    expect(maskPII("mail john@site.com ok")).toBe("mail ***@*** ok");
  });
  it("masks common tokens", () => {
    const s = "token=sk-ABCDEF123456 bearer ABCDEFGHIJKLMN";
    const m = maskPII(s);
    expect(m).not.toContain("sk-ABCDEF");
    expect(m).not.toContain("bearer ABCDE");
    expect(m).toContain("***");
  });
});

describe("format stability", () => {
  it("does not over-mask normal text", () => {
    const s = "hello world 12345";
    expect(maskPII(s)).toBe(s);
  });
});
