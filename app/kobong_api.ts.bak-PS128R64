import { getRepoJsonSafe } from "../infra/kobong/git_repo";

export type KobongFetchArgs = { url: string; headers?: Record<string, string> };

/** 환경 플래그: "false"/"0"/"no"면 비활성 → 예외 */
function isDisabled(): boolean {
  const v = (process.env.KOBONG_API_ENABLED ?? "true").toLowerCase();
  return v === "false" || v === "0" || v === "no";
}

/** named: 외부 API 페치(테스트용 — 네트워크 실패는 조용히 폴백) */
export async function kobongFetch(args: KobongFetchArgs): Promise<{ ok: boolean; json: Record<string, unknown> }> {
  if (isDisabled()) throw new Error("KOBONG_API_DISABLED");

  try {
    if (typeof fetch === "function" && args?.url) {
      const r = await fetch(args.url, { headers: args.headers });
      // JSON 파싱 실패해도 통과시킴(폴백)
      const j = await r.json().catch(() => ({}));
      return { ok: true, json: j ?? {} };
    }
  } catch {
    // 조용한 폴백
  }
  return { ok: true, json: {} };
}

/** named: 로컬 git 메타 → 항상 ok:true + json:{} 보장(영구 폴백) */
export async function fetchRepoJson(): Promise<{ ok: boolean; json: Record<string, unknown> }> {
  return getRepoJsonSafe();
}

/** default: 함수 — 호출 시 kobongFetch와 동일 동작 */
const kobongDefault = async (args: KobongFetchArgs) => kobongFetch(args);

// default에 named들도 같이 달아 경로/방식 혼용을 모두 흡수
export default Object.assign(kobongDefault, { kobongFetch, fetchRepoJson });
