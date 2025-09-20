export type WorkflowRun = { name:string; status:"success"|"failed"|"cancelled"|"in_progress"; duration:number; startedAt:string; };
export type PullRequest = { id:number; title:string; author:string; ageH:number; labels:string[]; draft?:boolean; };
export type Issue = { id:number; title:string; ageH:number; state:"open"|"closed"; labels:string[]; };
export type Release = { tag:string; publishedAt:string; prerelease?:boolean; };
export type Security = { dependabot:number; codeQL:number; secretScan:number; };
export type RepoSummary = { stars:number; forks:number; watchers:number; openIssues:number; openPRs:number; };

export type DashboardData = {
  summary: RepoSummary;
  workflows: WorkflowRun[];
  prs: PullRequest[];
  issuesOpen: Issue[];
  releases: Release[];
  security: Security;
  starsTrend: number[];
  issuesTrend: number[];
  commitsTrend: number[];
  ratelimit: { used:number; remaining:number; resetAt:string; };
};

function rnd(n:number, m:number){ return Math.floor(Math.random()*(m-n+1))+n }
function pick<T>(a:T[]){ return a[rnd(0,a.length-1)] }

export function makeFakeData(): DashboardData {
  const statuses:WorkflowRun["status"][]=["success","failed","cancelled","in_progress"];
  const workflows = Array.from({length:7}).map((_,i)=>({ name:`CI #${i+1}`, status: pick(statuses), duration: rnd(3,18), startedAt: new Date(Date.now()-rnd(0,8)*3600e3).toISOString() }));
  const prs = Array.from({length:8}).map((_,i)=>({ id:i+1, title:`Improve pipeline step ${i+1}`, author:["minsu","alice","bob","zoe"][i%4], ageH:rnd(1,140), labels: i%3? ["enhancement"]:["bug"], draft: i%5===0 }));
  const issuesOpen = Array.from({length:10}).map((_,i)=>({ id:i+1, title:`Fix #${100+i}`, ageH:rnd(1,300), state:"open" as const, labels: i%2? ["ui"]:["infra"] }));
  const releases = Array.from({length:4}).map((_,i)=>({ tag:`v0.${9+i}.${rnd(0,9)}`, publishedAt:new Date(Date.now()-i*86400e3).toISOString(), prerelease: i===0 && (i%2===0) }));
  const security = { dependabot:rnd(0,7), codeQL:rnd(0,3), secretScan:rnd(0,2) };
  const starsTrend = Array.from({length:24}).map(()=>rnd(30,120));
  const issuesTrend = Array.from({length:24}).map(()=>rnd(5,40));
  const commitsTrend = Array.from({length:24}).map(()=>rnd(1,30));
  const summary = { stars: 1287, forks: 212, watchers: 43, openIssues: issuesOpen.length, openPRs: prs.length };
  const ratelimit = { used:rnd(50,3000), remaining:rnd(1000,4500), resetAt: new Date(Date.now()+3600e3).toISOString() };
  return { summary, workflows, prs, issuesOpen, releases, security, starsTrend, issuesTrend, commitsTrend, ratelimit };
}