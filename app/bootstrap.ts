import { mkdirSync, appendFileSync } from 'fs';
import { join } from 'path';

const __LOG_DIR = 'logs';
mkdirSync(__LOG_DIR, { recursive: true });
appendFileSync(join(__LOG_DIR, 'app.log'), '');

const __entry = {
  timestamp: new Date().toISOString(),
  level: "INFO",
  traceId: Math.random().toString(36).slice(2),
  module: "bootstrap",
  action: "start",
  inputHash: "",
  outcome: "OK",
  durationMs: 0,
  errorCode: null,
  message: "bootstrap ok"
};
appendFileSync(join(__LOG_DIR, "app.log"), JSON.stringify(__entry) + "\n");/**
 * Minimal bootstrap for build sanity (Stage 8 patch).
 * - zero deps / stable console JSON
 */
function main() {
  const payload = {
    timestamp: new Date().toISOString(),
    module: "app",
    action: "bootstrap",
    outcome: "ok",
  };
  console.log(JSON.stringify(payload));
}
main();
export {}; // keep module scope


