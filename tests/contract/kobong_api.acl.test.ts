import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

async function loadAdapter() {
  const url = pathToFileURL(resolve("scripts/acl/kobong-api.mjs")).href;
  return await import(url);
}

describe("kobong-api adapter (contract)", () => {
  let logSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    logSpy = vi.spyOn(console, "log").mockImplementation(() => {});
  });

  afterEach(() => {
    logSpy.mockRestore();
    // @ts-expect-error -- lint gate
    globalThis.fetch = undefined;
  });

  it("prints pretty JSON when response is application/json", async () => {
    // mock fetch (JSON)
    // @ts-expect-error -- lint gate
// eslint-disable-next-line @typescript-eslint/no-explicit-any
    globalThis.fetch = vi.fn(async (url: string, init: any) => {
      const body = JSON.stringify({ echo: "ok" });
      return {
        ok: true,
        status: 200,
        statusText: "OK",
        headers: new Map([["content-type", "application/json"]]),
        text: async () => JSON.stringify({
          url,
          method: init?.method,
          headers: init?.headers,
          body: init?.body,
          received: { body }
        }),
// eslint-disable-next-line @typescript-eslint/no-explicit-any
      } as any;
    });

    const { default: call } = await loadAdapter();
    await call({
      method: "POST",
      url: "https://example.com/echo",
      headers: { "X-Trace": "abc" },
      data: "{\"ping\":1}",
      timeout: 1000,
    });

    const out = (logSpy.mock.calls[0]?.[0] as string) || "";
    const obj = JSON.parse(out);
    expect(obj.url).toBe("https://example.com/echo");
    expect(obj.method).toBe("POST");
    expect(obj.body).toBe("{\"ping\":1}");
    expect(obj.headers["X-Trace"]).toBe("abc");
  });

  it("prints plain text when response is not JSON", async () => {
    // mock fetch (text/plain)
    // @ts-expect-error -- lint gate
    globalThis.fetch = vi.fn(async () => {
      return {
        ok: true,
        status: 200,
        statusText: "OK",
        headers: new Map([["content-type", "text/plain"]]),
        text: async () => "OK",
// eslint-disable-next-line @typescript-eslint/no-explicit-any
      } as any;
    });

    const { default: call } = await loadAdapter();
    await call({
      method: "GET",
      url: "https://example.com/ping",
      headers: {},
      data: null,
      timeout: 1000,
    });

    const out = (logSpy.mock.calls[0]?.[0] as string) || "";
    expect(out).toBe("OK");
  });
});

