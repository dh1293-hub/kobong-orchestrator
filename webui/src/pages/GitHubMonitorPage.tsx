import React from "react";
import GhMonitorBoard from "../components/GhMonitorBoard";
import { DEFAULT_OWNER, DEFAULT_REPO, getCurrentGhEndpoint, getSuggestedRefreshMs, isPublicFallback } from "../services/github";

type Theme = "light" | "dark";
const FAV_KEY = "gh_favorites";
const THEME_KEY = "gh_theme";

function loadFavs(): string[] {
  try { const raw = localStorage.getItem(FAV_KEY); if(raw){ const a = JSON.parse(raw); if(Array.isArray(a)) return a; } } catch {}
  return ["dh1293-hub/kobong-orchestrator","vercel/next.js","facebook/react","microsoft/TypeScript"];
}
function saveFavs(a:string[]){ try{ localStorage.setItem(FAV_KEY, JSON.stringify(Array.from(new Set(a)))) }catch{} }
function loadTheme(): Theme { try { const t = localStorage.getItem(THEME_KEY) as Theme | null; if(t==="dark"||t==="light") return t; } catch {} return "light"; }
function saveTheme(t:Theme){ try{ localStorage.setItem(THEME_KEY, t) }catch{} }

export default function GitHubMonitorPage(){
  const [owner,setOwner] = React.useState<string>(DEFAULT_OWNER);
  const [repo,setRepo]   = React.useState<string>(DEFAULT_REPO);
  const [input,setInput] = React.useState<string>(`${DEFAULT_OWNER}/${DEFAULT_REPO}`);
  const [favs,setFavs]   = React.useState<string[]>(loadFavs());
  const [sel,setSel]     = React.useState<string>(`${DEFAULT_OWNER}/${DEFAULT_REPO}`);
  const [theme,setTheme] = React.useState<Theme>(loadTheme());

  React.useEffect(()=>{ document.body.style.background = theme==="dark" ? "#0b1220" : "#ffffff"; document.body.style.color = theme==="dark" ? "#e5e7eb" : "#111827"; saveTheme(theme); },[theme]);

  const endpoint = getCurrentGhEndpoint();
  const interval = getSuggestedRefreshMs();
  const lowMode  = isPublicFallback();
  const isDark   = theme==="dark";

  function applyFromInput(){
    const v = (input || "").trim().replace(/^https?:\/\/github\.com\//,'');
    const m = v.split("/");
    if(m.length >= 2){ setOwner(m[0]); setRepo(m[1]); setSel(`${m[0]}/${m[1]}`); }
    else { alert("형식은 owner/repo 입니다. 예: vercel/next.js"); }
  }
  function addFav(){
    const v = `${owner}/${repo}`; const next = Array.from(new Set([v, ...favs]));
    setFavs(next); saveFavs(next);
  }
  function removeFav(){
    const next = favs.filter(x => x !== sel);
    setFavs(next); saveFavs(next);
  }
  function pickFav(v:string){
    setSel(v); setInput(v);
    const m = v.split("/"); if(m.length>=2){ setOwner(m[0]); setRepo(m[1]); }
  }

  const cardStyle = { background: isDark ? "#0f172a" : "#ffffff", borderColor: isDark ? "#334155" : "#e5e7eb" };

  return (
    <div style={{maxWidth:1100,margin:"30px auto",padding:"0 16px",display:"flex",flexDirection:"column",gap:16}}>
      <div style={{display:"flex", alignItems:"center", justifyContent:"space-between"}}>
        <h1 style={{margin:0,fontSize:26}}>GitHub 모니터링</h1>
        <button onClick={()=>setTheme(isDark?"light":"dark")} style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8, background:isDark?"#111827":"#fff", color:isDark?"#e5e7eb":"#111827", cursor:"pointer"}}>
          {isDark ? "라이트 모드" : "다크 모드"}
        </button>
      </div>

      {/* 상태바 */}
      <div style={{display:"flex",gap:12,alignItems:"center",flexWrap:"wrap",padding:"8px 12px",border:"1px solid #e5e7eb",borderRadius:10,background:isDark?"#0f172a":"#fafafa", color:isDark?"#e5e7eb":"#374151", ...cardStyle}}>
        <div style={{fontSize:13}}><b>endpoint:</b> {endpoint}</div>
        <div style={{fontSize:13}}><b>auto-refresh:</b> {Math.round((interval||0)/60000)}m</div>
        {lowMode
          ? <div style={{fontSize:12,color:"#92400e",background:"#fffbeb",border:"1px solid #fde68a",borderRadius:8,padding:"2px 8px"}}>저대역폭 모드(무토큰)</div>
          : <div style={{fontSize:12,color:"#065f46",background:"#ecfdf5",border:"1px solid #a7f3d0",borderRadius:8,padding:"2px 8px"}}>풀옵션 모드</div>
        }
      </div>

      {/* 즐겨찾기 + 입력 바 */}
      <div style={{display:"flex",gap:10,alignItems:"center",flexWrap:"wrap",padding:"10px 12px",border:"1px solid #e5e7eb",borderRadius:10, ...cardStyle}}>
        <select onChange={e=>pickFav(e.target.value)} value={sel} style={{padding:"6px 8px",border:"1px solid #e5e7eb",borderRadius:8}}>
          {([sel, ...favs.filter(x=>x!==sel)]).map((v,i)=><option key={i} value={v}>{v}</option>)}
        </select>
        <button onClick={addFav} style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8, background:"#fff", cursor:"pointer"}}>현재 추가</button>
        <button onClick={removeFav} style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8, background:"#fff", cursor:"pointer"}}>선택 삭제</button>
        <input value={input} onChange={e=>setInput(e.target.value)} placeholder="owner/repo 또는 github URL"
               style={{minWidth:320,padding:"6px 8px",border:"1px solid #e5e7eb",borderRadius:8}} />
        <button onClick={applyFromInput} style={{padding:"6px 12px",border:"1px solid #e5e7eb",borderRadius:8, background:"#fff", cursor:"pointer"}}>적용</button>
        <div style={{fontSize:12,opacity:0.8}}>현재 대상: <b>{owner}/{repo}</b></div>
      </div>

      <GhMonitorBoard owner={owner} repo={repo} />
    </div>
  );
}
