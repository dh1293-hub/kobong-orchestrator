#!/usr/bin/env node
import process from "node:process";

function parseArgs(argv){
  const out = { method:"GET", url:"", headers:{}, data:null, timeout:15000, ua:"kobong-cli/1.1" };
  for (const a of argv) {
    if (a.startsWith("--url="))       out.url = a.slice(6);
    else if (a.startsWith("--method=")) out.method = a.slice(9).toUpperCase();
    else if (a.startsWith("--hdr=")) {
      const kv = a.slice(6).split(":");
      const k  = kv.shift().trim(); const v = kv.join(":").trim();
      if (k) out.headers[k] = v;
    } else if (a.startsWith("--data=")) {
      out.data = a.slice(7);
      if (!out.headers["Content-Type"]) out.headers["Content-Type"] = "application/json; charset=utf-8";
    } else if (a.startsWith("--timeout=")) out.timeout = parseInt(a.slice(10),10);
    else if (a.startsWith("--ua=")) out.ua = a.slice(5);
    else if (a === "-h" || a === "--help") out.help = true;
  }
  if (!out.headers["Accept"]) out.headers["Accept"]="application/json";
  if (!out.headers["User-Agent"]) out.headers["User-Agent"]=out.ua;

  // Env token → Authorization (if not provided)
  const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN || process.env.KOBONG_API_TOKEN;
  if (token && !out.headers["Authorization"]) out.headers["Authorization"] = `Bearer ${token}`;

  return out;
}

function printHelp(){
  console.error(`Usage:
  node kobong-api.mjs --url=<URL> [--method=GET|POST|PUT|PATCH|DELETE]
                      [--hdr=K:V] [--hdr=K:V]...
                      [--data='JSON'] [--timeout=15000] [--ua='name/1.0']
  Env tokens: GH_TOKEN | GITHUB_TOKEN | KOBONG_API_TOKEN (auto Authorization)
`);
}

async function call({method,url,headers,data,timeout}){
  const ac = new AbortController();
  const t  = setTimeout(()=>ac.abort(), timeout);
  try{
    const res = await fetch(url, {
      method,
      headers,
      body: data ? (/^\s*[\[{]/.test(data) ? data : String(data)) : null,
      signal: ac.signal
    });
    const ct = res.headers.get("content-type")||"";
    const text = await res.text();
    let out;
    if (ct.includes("json")) {
      try { out = JSON.stringify(JSON.parse(text), null, 2) } catch { out = text }
    } else out = text;
    if (!res.ok) {
      console.error(`[ERROR] HTTP ${res.status} ${res.statusText}\n` + out);
      process.exit(1);
    }
    console.log(out);
  } catch (e){
    console.error("[ERROR] request failed:", e.message || String(e));
    process.exit(1);
  } finally { clearTimeout(t); }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || !args.url) { printHelp(); process.exit(args.url ? 0 : 2); }
  call(args);
}

export default call;