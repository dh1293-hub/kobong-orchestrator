from fastapi import APIRouter, HTTPException
import os, httpx

router = APIRouter()
GH = "https://api.github.com"

def _cli():
    tok = os.environ.get("GITHUB_TOKEN")
    headers={"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"}
    if tok: headers["Authorization"]=f"Bearer {tok}"
    return httpx.Client(timeout=12.0, headers=headers)

@router.get("/summary")
def summary(owner:str, repo:str):
    try:
        with _cli() as c:
            rr = c.get(f"{GH}/repos/{owner}/{repo}")
            if rr.status_code==404: raise HTTPException(404,"repo not found")
            j = rr.json()
            stars=j.get("stargazers_count",0); forks=j.get("forks_count",0); open_issues=j.get("open_issues_count",0)
            prs_open = c.get(f"{GH}/search/issues", params={"q": f"repo:{owner}/{repo}+is:pr+is:open","per_page":1}).json().get("total_count",0)
            rel = c.get(f"{GH}/repos/{owner}/{repo}/releases/latest"); release = rel.json().get("tag_name") if rel.status_code==200 else None
            br  = c.get(f"{GH}/repos/{owner}/{repo}/branches", params={"per_page":1}); branches = 1
            if br.status_code==200 and "Link" in br.headers:
                try:
                    link = br.headers["Link"]; i = link.find("page="); branches = int(''.join(ch for ch in link[i+5:] if ch.isdigit())) if i!=-1 else 1
                except: pass
            co  = c.get(f"{GH}/repos/{owner}/{repo}/contributors", params={"per_page":1,"anon":"1"}); contributors = 1
            if co.status_code==200 and "Link" in co.headers:
                try:
                    link = co.headers["Link"]; i = link.find("page="); contributors = int(''.join(ch for ch in link[i+5:] if ch.isdigit())) if i!=-1 else 1
                except: pass
            ar = c.get(f"{GH}/repos/{owner}/{repo}/actions/runs", params={"per_page":100}); ok=tot=0
            if ar.status_code==200:
                for r in ar.json().get("workflow_runs", []):
                    if r.get("status")=="completed":
                        tot+=1; ok+=(1 if r.get("conclusion")=="success" else 0)
            pass_rate = round((ok/tot*100.0),1) if tot else 0.0
            return {"owner":owner,"repo":repo,"stars":stars,"forks":forks,"open_issues":open_issues,"prs_open":prs_open,"release":release,"branches":branches,"contributors":contributors,"ci_pass_rate":pass_rate}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.post("/token")
def set_token(token:str):
    os.environ["GITHUB_TOKEN"] = token.strip()
    return {"ok": True}

@router.get("/rate_limit")
def rate_limit():
    try:
        with _cli() as c:
            r = c.get(f"{GH}/rate_limit")
            j = r.json(); core=(j.get("resources") or {}).get("core") or {}
            return {"limit": core.get("limit",0), "remaining": core.get("remaining",0), "reset": core.get("reset")}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/releases")
def releases(owner:str, repo:str, per_page:int=20):
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/releases", params={"per_page":per_page})
            if r.status_code==404: raise HTTPException(404,"repo not found")
            items=[]
            for rel in r.json():
                items.append({"tag": rel.get("tag_name"), "name": rel.get("name") or rel.get("tag_name"),
                              "published_at": rel.get("published_at"), "draft": rel.get("draft",False),
                              "prerelease": rel.get("prerelease",False)})
            return {"items": items}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/compare")
def compare(owner:str, repo:str, base:str, head:str):
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/compare/{base}...{head}")
            if r.status_code==404: raise HTTPException(404,"not found")
            j = r.json()
            files = j.get("files") or []
            commits = j.get("commits") or []
            out = {
              "ahead_by": j.get("ahead_by"),
              "behind_by": j.get("behind_by"),
              "total_commits": j.get("total_commits"),
              "files": [{"filename":f.get("filename"),"changes":f.get("changes"),"additions":f.get("additions"),"deletions":f.get("deletions")} for f in files],
              "commits": [{"sha":(c.get("sha") or "")[:7], "message": (c.get("commit") or {}).get("message","").splitlines()[0], "author": ((c.get("commit") or {}).get("author") or {}).get("name"), "date": ((c.get("commit") or {}).get("author") or {}).get("date")} for c in commits]
            }
            return out
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/branch_builds")
def branch_builds(owner:str, repo:str, branches:int=8):
    try:
        with _cli() as c:
            br = c.get(f"{GH}/repos/{owner}/{repo}/branches", params={"per_page":branches})
            if br.status_code==404: raise HTTPException(404,"repo not found")
            out=[]
            for b in br.json():
                name = b.get("name")
                rr = c.get(f"{GH}/repos/{owner}/{repo}/actions/runs", params={"branch":name,"per_page":1})
                status, conclusion, when, url = None, None, None, None
                if rr.status_code==200:
                    runs = rr.json().get("workflow_runs") or []
                    if runs:
                        r0 = runs[0]
                        status = r0.get("status"); conclusion = r0.get("conclusion"); when=r0.get("updated_at"); url=r0.get("html_url")
                out.append({"branch":name,"status":status,"conclusion":conclusion,"updated_at":when,"html_url":url})
            return {"items": out}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/workflows_list")
def workflows_list(owner:str, repo:str, per_page:int=50):
    # .github/workflows/* 목록
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/actions/workflows", params={"per_page":per_page})
            if r.status_code==404: raise HTTPException(404,"repo not found")
            wfs=[]
            for w in r.json().get("workflows",[]):
                wfs.append({
                    "id": w.get("id"), "name": w.get("name") or "workflow", "state": w.get("state"),
                    "path": w.get("path"), "created_at": w.get("created_at"), "updated_at": w.get("updated_at")
                })
            return {"items": wfs}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/workflows_overview")
def workflows_overview(owner:str, repo:str, max:int=6, per_runs:int=10):
    # 워크플로우별 최근 실행 요약(성공률/마지막 결론)
    try:
        with _cli() as c:
            cat = c.get(f"{GH}/repos/{owner}/{repo}/actions/workflows", params={"per_page":max})
            if cat.status_code==404: raise HTTPException(404,"repo not found")
            over=[]
            for wf in (cat.json().get("workflows") or [])[:max]:
                wid = wf.get("id"); name=wf.get("name") or "workflow"
                rr = c.get(f"{GH}/repos/{owner}/{repo}/actions/workflows/{wid}/runs", params={"per_page": per_runs})
                last, ok, tot = None, 0, 0
                if rr.status_code==200:
                    runs = rr.json().get("workflow_runs") or []
                    for r in runs:
                        if r.get("status")=="completed":
                            tot += 1; ok += (1 if r.get("conclusion")=="success" else 0)
                        if not last: last = r
                rate = round((ok/tot*100.0),1) if tot else 0.0
                over.append({
                    "id": wid, "name": name, "success_rate": rate,
                    "last_status": (last or {}).get("status"), "last_conclusion": (last or {}).get("conclusion"),
                    "updated_at": (last or {}).get("updated_at"), "html_url": (last or {}).get("html_url")
                })
            return {"items": over}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")