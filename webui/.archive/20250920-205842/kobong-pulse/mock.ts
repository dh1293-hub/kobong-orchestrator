export function mock(range: string){
  const len = range==="24h"? 24 : range==="7d"? 28 : range==="30d"? 60 : 90;
  const rnd = (n:number,m:number)=> Math.round(n + Math.random()*m);
  const series = (base:number, vary:number)=> Array.from({length:len},()=> rnd(base, vary));
  const repos = Array.from({length:18},(_,i)=>({
    name:`repo-${(i+1).toString().padStart(2,"0")}`,
    stars:rnd(120,800),
    prs:rnd(2,25),
    issues:rnd(5,60),
    checks: Math.random() > .15,
    spark: series(40, 40),
  }));
  const rows = ["build","lint","test","release","e2e","docker"];
  const cols = repos.slice(0,12).map(r=>r.name);
  const values = rows.map(()=> cols.map(()=> Math.random()));
  return {
    kpis:{ repos: repos.length, openPRs: repos.reduce((a,b)=>a+b.prs,0), openIssues: repos.reduce((a,b)=>a+b.issues,0), failed: values.flat().filter(v=>v<.5).length, contributors: rnd(12,18)},
    trends:{ repos: series(12,3), prs: series(40,20), issues: series(60,30), failed: series(15,10), contrib: series(14,6)},
    prHealth:[
      {label:"Merged", value:rnd(60,40), tone:"emerald" as const},
      {label:"Reviewed", value:rnd(30,20), tone:"sky"     as const},
      {label:"Blocked", value:rnd(8,6),   tone:"amber"   as const},
      {label:"Failing", value:rnd(6,6),   tone:"rose"    as const},
      {label:"Draft",   value:rnd(10,8),  tone:"violet"  as const},
    ],
    prBreakdown:[
      {label:"Avg. merge time (h)", value:rnd(18,12), trend:series(10,6)},
      {label:"Reviews per PR", value:(Math.random()*3+1).toFixed(1), trend:series(8,5)},
      {label:"Code churn (%)", value:(Math.random()*20+5).toFixed(1), trend:series(12,8)},
    ],
    events:Array.from({length:18},(_,i)=>({
      id:i+1, title: (i%3===0? "Commit " : i%3===1? "Issue " : "Workflow ")
        + (Math.random().toString(36).slice(2,8)), repo: repos[i%repos.length].name,
      when: `${rnd(1,23)}h`, type: i%3===0? "commit" : i%3===1? "issue" : "check"
    })),
    heatmap:{ rows, cols, values },
    repos
  };
}