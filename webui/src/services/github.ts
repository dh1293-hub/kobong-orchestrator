import { GH_BASE, GH_PREFIX_CANDIDATES, GH_FALLBACK_BASES, DEFAULT_OWNER, DEFAULT_REPO, GH_TOKEN } from "./config";

export type GhSummary = {
  repo: { full_name: string; stargazers_count: number; forks_count: number; open_issues_count?: number; default_branch: string; };
  counts: { openIssues: number; openPRs: number; commits24h: number; };
  ci: { status: 'success'|'failure'|'neutral'|'cancelled'|'in_progress'|'queued'|'unknown'; lastRunUrl?: string; lastRunName?: string; updatedAt?: string; };
  release?: { tag_name: string; html_url: string; };
  rate: { remaining: number; limit: number; reset?: number; };
};

export type GhTrends = {
  days: string[]; commits: number[]; issues: number[]; prs: number[]; skippedReason?: string;
};

export type GhWorkflowRun = {
  id: number;
  name?: string;
  status?: string;
  conclusion?: string;
  branch?: string;
  html_url: string;
  created_at?: string;
  updated_at?: string;
  duration_sec?: number;
};

let chosenBase = GH_BASE;
let chosenPrefix = (import.meta.env.VITE_GH_PREFIX ?? "/github") as string;

function makeUrl(base: string, prefix: string, path: string){ const pre = prefix || ""; return `${base}${pre}${path}`; }
function gh(path: string){ return makeUrl(chosenBase, chosenPrefix, path); }

const etags = new Map<string,string>();
const cache = new Map<string,any>();

async function fetchWithTimeout(url: string, init?: RequestInit, ms=12000){
  const ctl = new AbortController(); const t = setTimeout(()=>ctl.abort(), ms);
  try { return await fetch(url, { ...init, signal: ctl.signal }); }
  finally { clearTimeout(t); }
}

function addGhHeaders(base: string, init?: RequestInit): RequestInit {
  const headers: Record<string,string> = { ...(init?.headers as any ?? {}) };
  if (base.includes("api.github.com")) {
    headers["Accept"] = "application/vnd.github+json";
    headers["X-GitHub-Api-Version"] = "2022-11-28";
    if (GH_TOKEN) headers["Authorization"] = `Bearer ${GH_TOKEN}`;
  }
  return { ...(init ?? {}), headers };
}

async function fetchGhRaw(path: string, init?: RequestInit): Promise<Response> {
  const bases = [chosenBase, ...GH_FALLBACK_BASES.filter(b => b !== chosenBase)];
  const prefixes = [chosenPrefix, ...GH_PREFIX_CANDIDATES.filter(p => p !== chosenPrefix)];
  let lastErr: any;
  for (const base of bases) {
    for (const prefix of prefixes) {
      const url = makeUrl(base, prefix, path);
      try {
        const r = await fetchWithTimeout(url, addGhHeaders(base, init));
        if (r.ok || r.status === 304) { chosenBase = base; chosenPrefix = prefix; return r; }
        let body = ""; try { body = await r.clone().text(); } catch {}
        if (r.status === 404 || body.includes("not_found")) { lastErr = new Error(`HTTP ${r.status}: ${body}`); continue; }
        throw new Error(`HTTP ${r.status}: ${body}`);
      } catch (e) { lastErr = e; continue; }
    }
  }
  throw lastErr ?? new Error("GitHub not reachable");
}

async function fetchJsonGhCached(path: string, init?: RequestInit){
  const key = `${chosenBase}|${chosenPrefix}|${path}`;
  const et  = etags.get(key);
  const hdrs = { ...(init?.headers as any ?? {}) } as any;
  if (et) hdrs["If-None-Match"] = et;
  const r = await fetchGhRaw(path, { ...(init ?? {}), headers: hdrs });
  if (r.status === 304 && cache.has(key)) return cache.get(key);
  const ct = r.headers.get("content-type") || "";
  const val = ct.includes("application/json") ? await r.json() : await r.text();
  const newTag = r.headers.get("etag") || undefined;
  if (newTag) etags.set(key, newTag);
  cache.set(key, val);
  return val;
}

export function getCurrentGhEndpoint(){ return `${chosenBase}${chosenPrefix || ""}`; }
export function isPublicFallback(){ return chosenBase.includes("api.github.com") && !GH_TOKEN; }
export function getSuggestedRefreshMs(){ return isPublicFallback() ? 600000 : 60000; } // 무토큰=10분, 토큰/브리지=1분
export { DEFAULT_OWNER, DEFAULT_REPO };

export async function loadGithubSummary(owner: string, repo: string): Promise<GhSummary> {
  const enc = encodeURIComponent;
  const rateData = await fetchJsonGhCached(`/rate_limit`).catch(()=> null) as any;
  const remaining = rateData?.rate?.remaining ?? 0;
  const limit     = rateData?.rate?.limit ?? (isPublicFallback() ? 60 : 5000);
  const since = new Date(Date.now() - 24*3600*1000).toISOString();

  const [repoInfo, issues, prs, runs, release, commits] = await Promise.allSettled([
    fetchJsonGhCached(`/repos/${owner}/${repo}`),
    fetchJsonGhCached(`/search/issues?q=repo:${owner}/${repo}+type:issue+state:open&per_page=1`),
    fetchJsonGhCached(`/search/issues?q=repo:${owner}/${repo}+type:pr+state:open&per_page=1`),
    fetchJsonGhCached(`/repos/${owner}/${repo}/actions/runs?per_page=1`).catch(()=>null),
    fetchJsonGhCached(`/repos/${owner}/${repo}/releases/latest`).catch(()=>null),
    fetchJsonGhCached(`/repos/${owner}/${repo}/commits?since=${enc(since)}&per_page=100`).catch(()=>[])
  ]);

  const repoObj:any = (repoInfo as any).status==='fulfilled' ? (repoInfo as any).value : {};
  const openIssues  = (issues as any).status==='fulfilled' ? ((issues as any).value?.total_count ?? repoObj.open_issues_count ?? 0) : (repoObj.open_issues_count ?? 0);
  const openPRs     = (prs as any).status==='fulfilled'    ? ((prs as any).value?.total_count ?? 0) : 0;

  let ciStatus:'success'|'failure'|'neutral'|'cancelled'|'in_progress'|'queued'|'unknown'='unknown', lastRunUrl:string|undefined, lastRunName:string|undefined, updatedAt:string|undefined;
  if ((runs as any).status==='fulfilled') {
    const wr = (runs as any).value?.workflow_runs?.[0];
    if (wr) {
      ciStatus = (wr.status==='completed') ? (wr.conclusion ?? 'neutral') : (wr.status ?? 'unknown');
      lastRunUrl = wr.html_url; lastRunName = wr.name ?? wr.display_title ?? wr.head_branch; updatedAt = wr.updated_at ?? wr.created_at;
    }
  }

  let releaseObj:any = undefined;
  if ((release as any).status==='fulfilled' && (release as any).value?.tag_name) {
    releaseObj = { tag_name: (release as any).value.tag_name, html_url: (release as any).value.html_url };
  }

  const commits24h = (commits as any).status==='fulfilled' && Array.isArray((commits as any).value) ? (commits as any).value.length : 0;

  return { repo: { full_name: repoObj.full_name ?? `${owner}/${repo}`, stargazers_count: repoObj.stargazers_count ?? 0, forks_count: repoObj.forks_count ?? 0, open_issues_count: repoObj.open_issues_count, default_branch: repoObj.default_branch ?? 'main' },
           counts: { openIssues, openPRs, commits24h },
           ci: { status: ciStatus, lastRunUrl, lastRunName, updatedAt },
           release: releaseObj,
           rate: { remaining, limit, reset: rateData?.rate?.reset } };
}

function dayKey(d: string | Date){
  const dt = (typeof d === "string") ? new Date(d) : d;
  const y = dt.getUTCFullYear(); const m = (dt.getUTCMonth()+1).toString().padStart(2,"0"); const da = dt.getUTCDate().toString().padStart(2,"0");
  return `${y}-${m}-${da}`;
}

/** 7일 트렌드(커밋/이슈/PR) — 요청 2회 */
export async function loadGithubTrends(owner: string, repo: string): Promise<GhTrends>{
  const now = new Date(); const since = new Date(now.getTime() - 7*24*3600*1000); const sinceIso = since.toISOString();
  const rate = await fetchJsonGhCached(`/rate_limit`).catch(()=>null) as any;
  const remaining = rate?.rate?.remaining ?? 0;
  if (isPublicFallback() && remaining < 10) { return { days: [], commits: [], issues: [], prs: [], skippedReason: "low-budget" }; }
  const days:string[] = []; for(let i=6;i>=0;i--){ days.push(dayKey(new Date(now.getTime() - i*24*3600*1000))); }
  const commits:any[] = await fetchJsonGhCached(`/repos/${owner}/${repo}/commits?since=${encodeURIComponent(sinceIso)}&per_page=100`).catch(()=>[]);
  const cMap = new Map<string,number>(); for(const c of commits){ const k=c?.commit?.author?.date?dayKey(c.commit.author.date):null; if(!k)continue; cMap.set(k,(cMap.get(k)??0)+1); }
  const q = `repo:${owner}/${repo} created:>=${sinceIso}`; const res = await fetchJsonGhCached(`/search/issues?q=${encodeURIComponent(q)}&sort=created&order=desc&per_page=100`).catch(()=>({ items:[] }));
  const iMap = new Map<string,number>(), pMap = new Map<string,number>();
  for(const it of (res?.items??[])){ const k=it?.created_at?dayKey(it.created_at):null; if(!k)continue; if(it?.pull_request) pMap.set(k,(pMap.get(k)??0)+1); else iMap.set(k,(iMap.get(k)??0)+1); }
  return { days, commits: days.map(d=>cMap.get(d)??0), issues: days.map(d=>iMap.get(d)??0), prs: days.map(d=>pMap.get(d)??0) };
}

/** 최근 워크플로 N개(기본 5) */
export async function loadRecentWorkflows(owner:string, repo:string, count=5): Promise<GhWorkflowRun[]>{
  const data:any = await fetchJsonGhCached(`/repos/${owner}/${repo}/actions/runs?per_page=${Math.max(1,Math.min(count,20))}`).catch(()=>null);
  const arr:any[] = data?.workflow_runs ?? [];
  return arr.slice(0, count).map(w=>{
    const created = w?.created_at ? new Date(w.created_at) : null;
    const updated = w?.updated_at ? new Date(w.updated_at) : null;
    const dur = (created && updated) ? Math.max(0, Math.round((updated.getTime()-created.getTime())/1000)) : undefined;
    return { id: w?.id, name: w?.name ?? w?.display_title ?? w?.head_branch, status: (w?.status==='completed' ? (w?.conclusion ?? 'neutral') : w?.status), conclusion: w?.conclusion, branch: w?.head_branch, html_url: w?.html_url, created_at: w?.created_at, updated_at: w?.updated_at, duration_sec: dur };
  });
}

export function resetGhCache(){ try { etags.clear(); cache.clear(); } catch {} }

export type GhTokenMeta = {
  present: boolean;
  user?: { login: string };
  scopes?: string[];
  rate?: { remaining: number; limit: number; reset?: number };
  base: string;
  prefix: string;
};

export async function getTokenMeta(): Promise<GhTokenMeta>{
  const meta: GhTokenMeta = { present: !!GH_TOKEN, base: chosenBase, prefix: chosenPrefix };
  try {
    const rUser = await fetchGhRaw(`/user`);
    try { const js = rUser.ok ? await rUser.clone().json() : null; if(js?.login) meta.user = { login: js.login }; } catch {}
    const scopes = rUser.headers.get('x-oauth-scopes');
    if (scopes) meta.scopes = scopes.split(',').map(s=>s.trim()).filter(Boolean);
  } catch {}
  try {
    const rRate = await fetchGhRaw(`/rate_limit`);
    const js = rRate.ok ? await rRate.clone().json() : null;
    const rate = js?.resources?.core ?? js?.rate ?? null;
    if(rate) meta.rate = { remaining: rate.remaining ?? 0, limit: rate.limit ?? 0, reset: rate.reset };
  } catch {}
  return meta;
}

/** 브리지 헬스(로컬 브리지일 때만 유효) */
export async function pingBridgeHealth(): Promise<{ok:boolean; status:number; body?:any}>{
  try {
    const url = `${chosenBase}/health`;
    const r = await fetchWithTimeout(url, undefined, 6000);
    const ct = r.headers.get('content-type') || '';
    const body = ct.includes('application/json') ? await r.clone().json() : await r.clone().text();
    return { ok: r.ok, status: r.status, body };
  } catch { return { ok:false, status:0 }; }
}
