import { readFileSync } from "node:fs";
import { execSync } from "node:child_process";

const pkg = JSON.parse(readFileSync("./package.json", "utf8"));
const want = pkg?.devDependencies?.typescript;
if (!want) {
  console.error("No devDependencies.typescript in package.json");
  process.exit(2);
}

const out = execSync("npx -y tsc -v", { stdio: ["ignore", "pipe", "pipe"] }).toString();
const got = (out.match(/\d+\.\d+\.\d+/) || [])[0];

if (got !== want) {
  console.error(`TypeScript mismatch. want=${want} got=${got}`);
  process.exit(2);
}
console.log(`TypeScript OK ${got}`);