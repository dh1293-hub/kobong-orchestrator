import { describe, it, expect } from "vitest";
import { kobongFetch } from "../../app/kobong_api";

describe("KOBONG API feature flag (contract)", () => {
  it("throws when disabled", async () => {
    const prev = process.env.KOBONG_API_ENABLED;
    process.env.KOBONG_API_ENABLED = "false";
    await expect(kobongFetch({ url: "https://example.com" })).rejects.toThrow("KOBONG_API_DISABLED");
    process.env.KOBONG_API_ENABLED = prev;
  });
});