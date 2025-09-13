/**
 * Allow TS >=5.3.0 <5.4.0 (eslint typescript-estree 지원 범위)
 * 출력만 하고, 범위를 벗어나면 process.exit(1)
 */
import { createRequire } from "module";
const require = createRequire(import.meta.url);

function parse(x) {
  const m = String(x).trim().match(/^(\d+)\.(\d+)\.(\d+)/);
  if (!m) return { major:0, minor:0, patch:0 };
  return { major:+m[1], minor:+m[2], patch:+m[3] };
}
function inRange(v) {
  const {major, minor} = v;
  if (major !== 5) return false;
  if (minor < 3) return false;    // >=5.3
  if (minor >= 4) return false;   // <5.4
  return true;
}
try {
  const ts = require("typescript");
  const v = parse(ts.version || "");
  const ok = inRange(v);
  console.log(`TypeScript ${ts.version} (${ok ? "OK" : "OUT OF RANGE"})`);
  if (!ok) process.exit(1);
} catch (e) {
  console.error("TypeScript check failed:", e?.message || e);
  process.exit(1);
}
