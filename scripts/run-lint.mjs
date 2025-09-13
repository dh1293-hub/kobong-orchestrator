import { spawn } from "node:child_process";
const child = spawn(process.execPath, ["./node_modules/eslint/bin/eslint.js", "."], { stdio: "inherit" });
child.on("exit", (code) => process.exit(code ?? 0));
