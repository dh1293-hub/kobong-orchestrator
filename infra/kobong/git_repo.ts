import { existsSync } from "fs";
import { join, dirname } from "path";
import { spawnSync } from "child_process";

export function findRepoRoot(startDir: string): string | null {
  let dir = startDir;
  for (let i = 0; i < 20; i++) {
    if (existsSync(join(dir, ".git"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

function runGit(args: string[], cwd: string) {
  // stdio 기본 pipe → 콘솔로 안 흘림(조용 모드)
  return spawnSync("git", args, { cwd, encoding: "utf-8" });
}

/** git 미존재/오류여도 항상 ok:true + json:{} 반환 */
export function getRepoJsonSafe(cwd = process.cwd()): { ok: boolean; json: Record<string, unknown> } {
  try {
    const root = findRepoRoot(cwd);
    if (!root) return { ok: true, json: {} };

    const rev = runGit(["rev-parse", "HEAD"], root);
    if (rev.status !== 0) return { ok: true, json: {} };
    const commit = (rev.stdout || "").trim();

    const remoteOut = runGit(["remote", "-v"], root);
    const remotes = (remoteOut.stdout || "").trim().split(/\r?\n/).filter(Boolean);

    return { ok: true, json: { commit, remotes } };
  } catch {
    return { ok: true, json: {} };
  }
}

// default도 제공(경로/방식 혼용 대비)
export default { getRepoJsonSafe };
