const API = "https://api.github.com";
export type RepoRef = { owner: string; repo: string };
export type GhRepo = { full_name:string; stargazers_count:number; forks_count:number; subscribers_count?:number; open_issues_count:number; archived?:boolean; pushed_at?:string; };
export type GhPull = { id:number; number:number; state:"open"|"closed"; merged_at:string|null; user?:{login:string}; title:string; created_at:string; };
export type GhIssue = { id:number; number:number; state:"open"|"closed"; user?:{login:string}; title:string; created_at:string; pull_request?:any };
export type GhRun = { id:number; name:string; status?:string; conclusion?:string|null; run_number:number; run_attempt?:number; created_at:string; updated_at:string; };
export type GhRelease = { id:number; tag_name:string; published_at:string; assets?:{id:number}[] };

function headers(token?: string): Headers {
  const h = new Headers();
  h.set("Accept","application/vnd.github+json");
  h.set("X-GitHub-Api-Version","2022-11-28");
  if(token && token.trim().length>0){ h.set("Authorization",`Bearer ${token}`); }
  return h;
}

async function j<T>(res: Response): Promise<T>{
  if(!res.ok){
    const msg = await res.text().catch(()=>res.statusText);
    throw new Error(`[${res.status}] ${res.url} :: ${msg}`);
  }
  return res.json() as Promise<T>;
}

export async function getRepo(ref: RepoRef, token?:string){ 
  return j<GhRepo>( await fetch(`${API}/repos/${ref.owner}/${ref.repo}`, { headers: headers(token), cache:"no-store" }) );
}
export async function getPulls(ref: RepoRef, token?:string, per=30){ 
  return j<GhPull[]>( await fetch(`${API}/repos/${ref.owner}/${ref.repo}/pulls?state=all&per_page=${per}`, { headers: headers(token), cache:"no-store" }) );
}
export async function getIssues(ref: RepoRef, token?:string, per=30){ 
  const all = await j<GhIssue[]>( await fetch(`${API}/repos/${ref.owner}/${ref.repo}/issues?state=all&per_page=${per}`, { headers: headers(token), cache:"no-store" }) );
  return all.filter(x=>!x.pull_request);
}
export async function getRuns(ref: RepoRef, token?:string, per=20){
  const r = await j<{workflow_runs:GhRun[]}>( await fetch(`${API}/repos/${ref.owner}/${ref.repo}/actions/runs?per_page=${per}`, { headers: headers(token), cache:"no-store" }) );
  return r.workflow_runs ?? [];
}
export async function getReleases(ref: RepoRef, token?:string, per=10){
  return j<GhRelease[]>( await fetch(`${API}/repos/${ref.owner}/${ref.repo}/releases?per_page=${per}`, { headers: headers(token), cache:"no-store" }) );
}
export async function getRate(token?:string){
  return j<any>( await fetch(`${API}/rate_limit`, { headers: headers(token), cache:"no-store" }) );
}

export type DashData = {
  repo?: GhRepo;
  pulls: GhPull[];
  issues: GhIssue[];
  runs: GhRun[];
  releases: GhRelease[];
};
export async function loadAll(ref: RepoRef, token?:string): Promise<DashData>{
  const [repo, pulls, issues, runs, releases] = await Promise.all([
    getRepo(ref, token).catch(()=>undefined),
    getPulls(ref, token).catch(()=>[]),
    getIssues(ref, token).catch(()=>[]),
    getRuns(ref, token).catch(()=>[]),
    getReleases(ref, token).catch(()=>[]),
  ]);
  return { repo, pulls, issues, runs, releases };
}