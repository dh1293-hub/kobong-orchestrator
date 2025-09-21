from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os, httpx
router = APIRouter()
GH = "https://api.github.com"

def _cli():
    tok = os.environ.get("GITHUB_TOKEN")
    headers={"Accept":"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"}
    if tok: headers["Authorization"]=f"Bearer {tok}"
    return httpx.Client(timeout=10.0, headers=headers)

class TokenIn(BaseModel):
    token: str

@router.post("/token")
def set_token(body: TokenIn):
    os.environ["GITHUB_TOKEN"] = body.token.strip()
    return {"ok": True}

@router.get("/rate_limit")
def rate_limit():
    try:
        with _cli() as c:
            r = c.get(f"{GH}/rate_limit")
            j = r.json()
            core = (j.get("resources") or {}).get("core") or {}
            return {"limit": core.get("limit", 0), "remaining": core.get("remaining", 0), "reset": core.get("reset")}
    except httpx.ConnectError:
        raise HTTPException(503, "github unreachable")

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

@router.get("/prs")
def prs(owner:str, repo:str, state:str="open", per_page:int=10):
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/pulls", params={"state":state,"per_page":per_page,"sort":"updated"})
            if r.status_code==404: raise HTTPException(404,"repo not found")
            out=[]
            for p in r.json():
                out.append({"number":p.get("number"),"title":p.get("title"),"user":(p.get("user") or {}).get("login"),
                            "draft":p.get("draft",False),"updated_at":p.get("updated_at"),"comments":p.get("comments",0),"html_url":p.get("html_url")})
            return {"items": out}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/commits")
def commits(owner:str, repo:str, per_page:int=10):
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/commits", params={"per_page":per_page})
            if r.status_code==404: raise HTTPException(404,"repo not found")
            out=[]
            for cm in r.json():
                sha = (cm.get("sha") or "")[:7]
                commit = cm.get("commit") or {}
                msg = (commit.get("message") or "").splitlines()[0]
                author = (commit.get("author") or {}).get("name") or ((cm.get("author") or {}).get("login"))
                date = (commit.get("author") or {}).get("date")
                out.append({"sha":sha,"message":msg,"author":author,"date":date})
            return {"items": out}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/issues")
def issues(owner:str, repo:str, state:str="open", per_page:int=10):
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/issues", params={"state":state,"per_page":per_page})
            if r.status_code==404: raise HTTPException(404,"repo not found")
            out=[]
            for it in r.json():
                if "pull_request" in it: 
                    continue
                out.append({"number":it.get("number"),"title":it.get("title"),"user":(it.get("user") or {}).get("login"),
                            "labels":[l.get("name") for l in it.get("labels",[])], "updated_at":it.get("updated_at"), "html_url":it.get("html_url")})
            return {"items": out}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")

@router.get("/workflows")
def workflows(owner:str, repo:str, per_page:int=10):
    try:
        with _cli() as c:
            r = c.get(f"{GH}/repos/{owner}/{repo}/actions/runs", params={"per_page":per_page})
            if r.status_code==404: raise HTTPException(404,"repo not found")
            out=[]
            for w in r.json().get("workflow_runs", []):
                out.append({"id":w.get("id"),"name":(w.get("name") or w.get("display_title") or "workflow"),
                            "event":w.get("event"),"status":w.get("status"),"conclusion":w.get("conclusion"),
                            "updated_at":w.get("updated_at"),"html_url":w.get("html_url")})
            return {"items": out}
    except httpx.ConnectError: raise HTTPException(503,"github unreachable")