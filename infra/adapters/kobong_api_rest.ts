/* eslint-disable no-useless-escape */ // TODO(PS-12.6): refine regex
/* eslint-disable @typescript-eslint/no-explicit-any */ // TODO(PS-12.6): type properly
import { resolve } from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { KobongApiPort, KobongRequest, KobongResponse } from "../../domain/ports/kobong_api";

const pexec = promisify(execFile);

function tryParseJson(raw: string): unknown | undefined {
  const tryOnce = (s: string) => { try { return JSON.parse(s); } catch { return undefined; } };
  let v = tryOnce(raw);
  if (v !== undefined) return v;
  const noBom = raw.replace(/^\uFEFF/, "");
  v = tryOnce(noBom);
  if (v !== undefined) return v;
  const i = noBom.search(/[\{\[]/);
  if (i >= 0) {
    v = tryOnce(noBom.slice(i));
    if (v !== undefined) return v;
  }
  return undefined;
}

function buildHeaders(given?: Record<string,string>): Record<string,string> {
  const h: Record<string,string> = Object.assign({}, given || {});
  if (!h["Accept"]) h["Accept"] = "application/json";
  if (!h["User-Agent"]) h["User-Agent"] = "kobong-adapter/1.0";
  const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN || process.env.KOBONG_API_TOKEN;
  if (token && !h["Authorization"]) h["Authorization"] = `Bearer ${token}`;
  return h;
}

async function directFetch(req: KobongRequest): Promise<KobongResponse> {
  const headers = buildHeaders(req.headers);
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), req.timeoutMs ?? 15000);
  try {
    const res = await fetch(req.url, {
      method: req.method || "GET",
      headers,
      body: req.data ?? null,
      signal: ac.signal,
    } as any);
    const text = await res.text();
    const json = tryParseJson(text);
    if (!res.ok) {
      return { ok: false, status: res.status, statusText: res.statusText, bodyText: text.trim() };
    }
    return { ok: true, bodyText: text.trim(), json };
  } finally {
    clearTimeout(t);
  }
}

export class KobongApiRestAdapter implements KobongApiPort {
  async request(req: KobongRequest): Promise<KobongResponse> {
    const cli = resolve("scripts/acl/kobong-api.mjs");
    const args: string[] = [`--url=${req.url}`];

    if (req.method) args.push(`--method=${req.method}`);
    if (req.timeoutMs) args.push(`--timeout=${req.timeoutMs}`);
    if (req.data != null) args.push(`--data=${req.data}`);
    const headers = buildHeaders(req.headers);
    for (const [k, v] of Object.entries(headers)) args.push(`--hdr=${k}:${v}`);

    try {
      const { stdout } = await pexec(process.execPath, [cli, ...args], { encoding: "utf8" });
      const text = (stdout ?? "").trim();
      const json = tryParseJson(text);
      if (json === undefined || text.length === 0) {
        // ?대갚: 吏곸젒 fetch ?ъ떆??        return await directFetch(req);
      }
      return { ok: true, bodyText: text, json };
    } catch (e: any) {
      // exec ?ㅽ뙣 ?쒖뿉???대갚
      return await directFetch(req);
    }
  }
}

