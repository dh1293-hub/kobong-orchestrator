import fs from "node:fs";
import path from "node:path";
const src = path.resolve(".env.sample");
const dst = path.resolve(".env");
if (!fs.existsSync(dst) && fs.existsSync(src)) {
  fs.copyFileSync(src, dst);
  console.log("Created .env from .env.sample");
} else {
  console.log(".env already exists or .env.sample missing — nothing to do.");
}
