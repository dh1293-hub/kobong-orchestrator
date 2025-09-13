import { describe, it, expect } from "vitest";
import { LogEvent } from "../../src/contracts.logEvent";

describe("contract: LogEvent", () => {
  it("accepts a valid event", () => {
    const val = {
      timestamp: new Date().toISOString(),
      level: "INFO",
      traceId: "t-123",
      module: "domain",
      action: "compute",
      inputHash: "abc123",
      outcome: "ok",
      durationMs: 42,
      message: "done"
    };
    expect(() => LogEvent.parse(val)).not.toThrow();
  });

  it("rejects invalid level", () => {
// eslint-disable-next-line @typescript-eslint/no-explicit-any
    const bad: any = { 
      timestamp: "2025-01-01T00:00:00Z",
      level: "NOTICE",
      traceId: "t",
      module: "m",
      action: "a",
      inputHash: "h",
      outcome: "ok",
      durationMs: 0,
      message: "x"
    };
    expect(() => LogEvent.parse(bad)).toThrow();
  });
});
