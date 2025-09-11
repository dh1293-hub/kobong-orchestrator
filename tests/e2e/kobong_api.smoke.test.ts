/* eslint-disable no-useless-escape */ // TODO(PS-12.6): refine regex and remove
import { it, expect } from "vitest";
import { execSync } from "node:child_process";
import { kobongFetch } from "../../app/kobong_api";

function repoSlug(): string {
  const url = execSync("git config --get remote.origin.url", { encoding: "utf8" }).trim();
  // e.g. https://github.com/owner/repo.git  or  git@github.com:owner/repo.git
// eslint-disable-next-line no-useless-escape
  const m = url.match(/github\.com[:\/]([^\/]+)\/([^\.]+)(?:\.git)?$/i);
  if (!m) throw new Error("cannot parse remote.origin.url: " + url);
  return `${m[1]}/${m[2]}`;
}

it("E2E smoke: fetch repo json via kobong (app?뭦ort?뭝nfra)", async () => {
  process.env.KOBONG_API_ENABLED = "true";
  const slug = repoSlug();
  const res = await kobongFetch({
    url: `https://api.github.com/repos/${slug}`,
    headers: { "Accept": "application/vnd.github+json" },
    timeoutMs: 12000
  });

  expect(res.ok).toBe(true);
  expect(typeof res.json).toBe("object");
// eslint-disable-next-line @typescript-eslint/no-explicit-any
  const obj = res.json as any;
  expect(obj.full_name).toBe(slug);
}, 20000);



