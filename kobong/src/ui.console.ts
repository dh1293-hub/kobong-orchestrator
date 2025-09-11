import { add } from "./math.js";
import { logEvent } from "./logger.js";
import { randomUUID } from "node:crypto";
import readline from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

async function main() {
  const rl = readline.createInterface({ input, output });
  console.log("=== Kobong Console UI (Stage-6) ===");
  const a = Number(await rl.question("Enter A: "));
  const b = Number(await rl.question("Enter B: "));
  const sum = add(a, b);
  console.log(`A + B = ${sum}`);

  const evt = {
    timestamp: new Date().toISOString(),
    level: "INFO" as const,
    traceId: randomUUID(),
    module: "ui",
    action: "add",
    inputHash: `a=${a}&b=${b}`,
    outcome: `sum=${sum}`,
    durationMs: 0,
    message: "console-add"
  };
  logEvent(evt);
  console.log("Logged to ../logs/kobong.log");
  rl.close();
}

main().catch(err => {
  console.error("[ERROR]", err?.message ?? err);
  process.exit(1);
});