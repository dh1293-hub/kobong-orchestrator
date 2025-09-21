import React from "react";
import { loadGithubSummary, GhSummary, getCurrentGhEndpoint, getSuggestedRefreshMs, isPublicFallback, resetGhCache, loadGithubTrends, GhTrends, loadRecentWorkflows, GhWorkflowRun } from "../services/github";

type Props = { owner: string; repo: string; onError?: (e:Error)=>void; refreshMs?: number };

function Sparkline({ data, width=180, height=40 }: { data: number[]; width?: number; height?: number }){
  const max = Math.max(1, ...data);
  const step = (data.length>1) ? (width/(data.length-1)) : 0;
  const pts = data.map((v,i)=>`${i*step},${height - (v/max)*height}`).join(" ");
  return (<svg width={width} height={height} style={{display:"block"}}><polyline points={pts} fill="none" stroke="#ef4444" strokeWidth="2" /></svg>);
}

function toCsv(rows: string[][]){
  const esc = (s:string)=> `"${(s??"").replace(/"/g,'""')}"`;
  return rows.map(r => r.map(esc).join(",")).join("\r\n");
}

export default function GhMonitorBoard({ owner, repo, onError, refreshMs }: Props){
  const [data,setData] = React.useState<GhSummary|null>(null);
  const [tr,setTr] = React.useState<GhTrends|null>(null);
  const [runs,setRuns] = React.useState<GhWorkflowRun[]|null>(null);
  const [loading,setLoading] = React.useState(false);
  const [err,setErr] = React.useState<string|null>(null);
  const [ts,setTs] = React.useState<string>("");

  const interval = refreshMs ?? getSuggestedRefreshMs();

  const load = React.useCallback(async ()=>{
    setLoading(true); setErr(null);
    try{
      const [d, t, r] = await Promise.all([
        loadGithubSummary(owner, repo),
        loadGithubTrends(owner, repo).catch(()=>null),
        loadRecentWorkflows(owner, repo, 5).catch(()=>[])
      ]);
      setData(d); setTr(t); setRuns(r); setTs(new Date().toLocaleString());
    }catch(e:any){
      setErr(e?.message ?? "failed"); onError?.(e);
    }finally{ setLoading(false); }
  },[owner,repo,onError]);

  React.useEffect(()=>{ load(); },[load]);
  React.useEffect(()=>{ if(!interval) return; const id=setInterval(()=>load(), interval); return ()=>clearInterval(id); },[interval,load]);

  const Pill = ({label,value}:{label:string; value:React.ReactNode}) => (
    <div style={{padding:"10px 14px",border:"1px solid #e5e7eb",borderRadius:12,display:"flex",flexDirection:"column",gap:4,minWidth:160}}>
      <div style={{fontSize:12,color:"#6b7280"}}>{label}</div>
      <div style={{fontSize:18,fontWeight:700}}>{value}</div>
    </div>
  );
  const statusColors: Record<string,string> = { success:"#16a34a", failure:"#dc2626", cancelled:"#6b7280", in_progress:"#2563eb", queued:"#f59e0b", neutral:"#6b7280", unknown:"#9ca3af" };

  const endpoint = getCurrentGhEndpoint();
  const lowMode  = isPublicFallback();

  const showCiAlert = !!(data?.ci && (data.ci.status === 'failure' || data.ci.status === 'cancelled'));
  const showRateWarn = !!(data?.rate && data.rate.remaining < Math.min(500, Math.floor((data.rate.limit||5000)*0.15)));

  const downloadJson = React.useCallback(()=>{
    if(!data){ alert("데이터가 아직 없습니다."); return; }
    const blob = new Blob([JSON.stringify({summary:data, trends:tr, runs:runs??[]},null,2)], { type: "application/json" });
    const url = URL.createObjectURL(blob); const a = document.createElement("a");
    a.href = url; a.download = `gh-summary-${owner}-${repo}-${Date.now()}.json`;
    document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  },[data,tr,runs,owner,repo]);

  const downloadCsv = React.useCallback(()=>{
    if(!data){ alert("데이터가 아직 없습니다."); return; }
    const rows:string[][] = [];
    rows.push(["Section","Key","Value"]);
    rows.push(["Repo","full_name", data.repo.full_name]);
    rows.push(["Repo","stars", String(data.repo.stargazers_count)]);
    rows.push(["Repo","forks", String(data.repo.forks_count)]);
    rows.push(["Counts","openIssues", String(data.counts.openIssues)]);
    rows.push(["Counts","openPRs", String(data.counts.openPRs)]);
    rows.push(["Counts","commits24h", String(data.counts.commits24h)]);
    rows.push(["Rate","remaining/limit", `${data.rate.remaining}/${data.rate.limit}`]);
    if(tr?.days?.length){
      rows.push(["","",""]);
      rows.push(["Trend-Commits","date","value"]); tr.days.forEach((d,i)=>rows.push(["Trend-Commits", d, String(tr.commits[i] ?? 0)]));
      rows.push(["","",""]);
      rows.push(["Trend-Issues","date","value"]);  tr.days.forEach((d,i)=>rows.push(["Trend-Issues", d, String(tr.issues[i] ?? 0)]));
      rows.push(["","",""]);
      rows.push(["Trend-PRs","date","value"]);     tr.days.forEach((d,i)=>rows.push(["Trend-PRs", d, String(tr.prs[i] ?? 0)]));
    }
    const csv = toCsv(rows);
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob); const a = document.createElement("a");
    a.href = url; a.download = `gh-report-${owner}-${repo}-${Date.now()}.csv`;
    document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  },[data,tr,owner,repo]);

  return (
    <div style={{display:"flex",flexDirection:"column",gap:16}}>
      <div style={{display:"flex",alignItems:"center",gap:12,flexWrap:"wrap"}}>
        <h2 style={{margin:0,fontSize:22}}>GitHub 모니터</h2>
        <div style={{fontSize:12,color:"#9ca3af"}}>endpoint: {endpoint}</div>
        <div style={{fontSize:12,color:"#9ca3af"}}>auto-refresh: {Math.round((interval||0)/60000)}m</div>
        {lowMode
          ? <div style={{fontSize:12,color:"#92400e",background:"#fffbeb",border:"1px solid #fde68a",borderRadius:8,padding:"2px 8px"}}>저대역폭 모드</div>
          : <div style={{fontSize:12,color:"#065f46",background:"#ecfdf5",border:"1px solid #a7f3d0",borderRadius:8,padding:"2px 8px"}}>풀옵션 모드</div>
        }
        {showRateWarn && <div style={{fontSize:12,color:"#92400e",background:"#fff7ed",border:"1px solid #fed7aa",borderRadius:8,padding:"2px 8px"}}>레이트리밋 낮음</div>}
        <button onClick={()=>{ resetGhCache(); alert("캐시를 비웠습니다."); }} style={{padding:"6px 10px",borderRadius:8,border:"1px solid #e5e7eb",background:"#fff",cursor:"pointer"}}>캐시 비우기</button>
        <button onClick={downloadJson} style={{padding:"6px 10px",borderRadius:8,border:"1px solid #e5e7eb",background:"#fff",cursor:"pointer"}}>JSON 저장</button>
        <button onClick={downloadCsv} style={{padding:"6px 10px",borderRadius:8,border:"1px solid #e5e7eb",background:"#fff",cursor:"pointer"}}>CSV 내보내기</button>
        <button onClick={load} disabled={loading} style={{padding:"6px 10px",borderRadius:8,border:"1px solid #e5e7eb",background:loading?"#f3f4f6":"#fff",cursor:"pointer"}}>새로고침</button>
        <div style={{fontSize:12,color:"#6b7280"}}> {ts && `업데이트: ${ts}`}</div>
      </div>

      {err && <div style={{color:"#b91c1c",padding:"8px 10px",border:"1px solid #fecaca",background:"#fff1f2",borderRadius:8}}>오류: {err}</div>}

      {showCiAlert && (
        <div style={{color:"#b91c1c",padding:"8px 10px",border:"1px solid #fecaca",background:"#fff1f2",borderRadius:8}}>
          워크플로 실패 감지: <b>{data?.ci?.status}</b> — {data?.ci?.lastRunName ?? "최근 실행"}
          {data?.ci?.lastRunUrl && <> — <a href={data.ci.lastRunUrl} target="_blank">열기</a></>}
        </div>
      )}

      {/* 핵심 카드 */}
      <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(200px,1fr))",gap:12}}>
        <Pill label="저장소" value={data?.repo.full_name ?? `${owner}/${repo}`} />
        <Pill label="⭐ Stars" value={data?.repo.stargazers_count ?? "…"} />
        <Pill label="🍴 Forks" value={data?.repo.forks_count ?? "…"} />
        <Pill label="🐛 Open Issues" value={data?.counts.openIssues ?? "…"} />
        <Pill label="🔀 Open PRs" value={data?.counts.openPRs ?? "…"} />
        <Pill label="🕒 Commits 24h" value={data?.counts.commits24h ?? "…"} />
        <Pill label="⏳ Rate" value={data ? `${data.rate.remaining}/${data.rate.limit}` : "…"} />
      </div>

      {/* 7일 트렌드 */}
      <div style={{padding:14,border:"1px solid #e5e7eb",borderRadius:12}}>
        <div style={{fontSize:13,color:"#6b7280",marginBottom:10}}>7일 트렌드</div>
        {tr?.skippedReason ? (
          <div style={{color:"#6b7280"}}>예산 절약 모드로 트렌드를 생략했습니다.</div>
        ) : tr ? (
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:16}}>
            <div style={{display:"flex",flexDirection:"column",gap:6}}>
              <div style={{fontSize:12,color:"#6b7280"}}>커밋</div>
              <div style={{color:"#111827"}}><Sparkline data={tr.commits} /></div>
            </div>
            <div style={{display:"flex",flexDirection:"column",gap:6}}>
              <div style={{fontSize:12,color:"#6b7280"}}>이슈 생성</div>
              <div style={{color:"#111827"}}><Sparkline data={tr.issues} /></div>
            </div>
            <div style={{display:"flex",flexDirection:"column",gap:6}}>
              <div style={{fontSize:12,color:"#6b7280"}}>PR 생성</div>
              <div style={{color:"#111827"}}><Sparkline data={tr.prs} /></div>
            </div>
          </div>
        ) : <>…</>}
      </div>

      {/* 최근 워크플로 5개 */}
      <div style={{padding:14,border:"1px solid #e5e7eb",borderRadius:12}}>
        <div style={{fontSize:13,color:"#6b7280",marginBottom:10}}>최근 워크플로 5개</div>
        {Array.isArray(runs) ? (
          runs.length ? (
            <div style={{overflowX:"auto"}}>
              <table style={{width:"100%", borderCollapse:"collapse"}}>
                <thead>
                  <tr>
                    <th style={{textAlign:"left",borderBottom:"1px solid #e5e7eb",padding:"6px"}}>이름</th>
                    <th style={{textAlign:"left",borderBottom:"1px solid #e5e7eb",padding:"6px"}}>브랜치</th>
                    <th style={{textAlign:"left",borderBottom:"1px solid #e5e7eb",padding:"6px"}}>상태</th>
                    <th style={{textAlign:"left",borderBottom:"1px solid #e5e7eb",padding:"6px"}}>지속(초)</th>
                    <th style={{textAlign:"left",borderBottom:"1px solid #e5e7eb",padding:"6px"}}>링크</th>
                  </tr>
                </thead>
                <tbody>
                  {runs.map((r)=>(
                    <tr key={r.id}>
                      <td style={{padding:"6px"}}>{r.name ?? "(이름 없음)"}</td>
                      <td style={{padding:"6px"}}>{r.branch ?? "-"}</td>
                      <td style={{padding:"6px"}}><code>{r.status}</code></td>
                      <td style={{padding:"6px"}}>{r.duration_sec ?? "-"}</td>
                      <td style={{padding:"6px"}}><a href={r.html_url} target="_blank">열기</a></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : <div style={{color:"#6b7280"}}>워크플로 실행 기록이 없습니다.</div>
        ) : <>…</>}
      </div>

      {/* CI / 릴리스 */}
      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
        <div style={{padding:14,border:"1px solid #e5e7eb",borderRadius:12}}>
          <div style={{fontSize:13,color:"#6b7280",marginBottom:6}}>CI 상태</div>
          {data?.ci
            ? <div style={{display:"flex",flexDirection:"column",gap:6}}>
                <div><b>{data.ci.lastRunName ?? "최근 실행"}</b></div>
                <div>
                  <span style={{display:"inline-flex",alignItems:"center",gap:6}}>
                    <span style={{width:10,height:10,borderRadius:"50%",background:statusColors[data.ci.status] ?? "#9ca3af"}}></span>
                    <code>{data.ci.status}</code>
                  </span>
                </div>
                {data.ci.updatedAt && <div>updated: {new Date(data.ci.updatedAt).toLocaleString()}</div>}
                {data.ci.lastRunUrl && <a href={data.ci.lastRunUrl} target="_blank">열기</a>}
              </div>
            : <>…</>}
        </div>
        <div style={{padding:14,border:"1px solid #e5e7eb",borderRadius:12}}>
          <div style={{fontSize:13,color:"#6b7280",marginBottom:6}}>최신 릴리스</div>
          {data?.release
            ? <div><b>{data.release.tag_name}</b> — <a href={data.release.html_url} target="_blank">릴리스 페이지</a></div>
            : <div>없음 또는 비공개</div>}
        </div>
      </div>
    </div>
  );
}

