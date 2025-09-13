import { spawn } from "node:child_process";

// Run tsc via Node for cross-platform reliability
const child = spawn(process.execPath, ["./node_modules/typescript/bin/tsc", "-p", "tsconfig.json", "--noEmit"], {
  stdio: "inherit"
});
child.on("exit", (code) => process.exit(code ?? 0));
