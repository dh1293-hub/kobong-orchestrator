import { createWriteStream, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { LogEvent } from "./contracts.logEvent.js";

const LOG_PATH = join(process.cwd(), "..", "logs", "kobong.log");

function ensureFile() {
  const dir = dirname(LOG_PATH);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
}

export function logEvent(e: LogEvent) {
  // 怨꾩빟 寃利?(throw ???뚯뒪?멸? ?≪븘??
  const data = LogEvent.parse(e);
  ensureFile();
  const line = JSON.stringify(data);
  const out = createWriteStream(LOG_PATH, { flags: "a" });
  out.write(line + "\n");
  out.close();
}