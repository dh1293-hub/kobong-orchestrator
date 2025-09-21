from fastapi import APIRouter, Request
import typing as T, json, os
from .chat_feed import ChatItem, _append

router = APIRouter()

@router.post("/webhook")
async def github_webhook(request: Request):
    ev = request.headers.get("X-GitHub-Event","")
    try:
        body = await request.json()
    except:
        body = {}
    owner = (((body.get("repository") or {}).get("owner") or {}).get("login"))
    repo  = (body.get("repository") or {}).get("name")
    url   = (body.get("repository") or {}).get("html_url")
    title = None; text=None; channel=None

    if ev=="issue_comment":
        channel="issue_comment"
        title = (body.get("issue") or {}).get("title")
        text  = (body.get("comment") or {}).get("body")
        url   = (body.get("comment") or {}).get("html_url") or url
    elif ev in ("pull_request_review_comment","pull_request_review","pull_request"):
        channel="pr_comment"
        title = ((body.get("pull_request") or {}).get("title")) or "pull_request"
        text  = ((body.get("comment") or {}).get("body")) or ((body.get("review") or {}).get("body"))
        url   = ((body.get("comment") or {}).get("html_url")) or ((body.get("pull_request") or {}).get("html_url")) or url
    elif ev.startswith("discussion"):
        channel="discussion"
        title = (body.get("discussion") or {}).get("title")
        text  = ((body.get("comment") or {}).get("body"))
        url   = ((body.get("comment") or {}).get("html_url")) or ((body.get("discussion") or {}).get("html_url")) or url
    else:
        # 그 외 이벤트는 간단 로깅만
        channel = ev or "event"
        title   = (body.get("action") or "event")
        text    = None

    item = ChatItem(dir="in", owner=owner, repo=repo, channel=channel, url=url, title=title, text=text, source="github", target="kobong-orchestrator")
    return _append(item)