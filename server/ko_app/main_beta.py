from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from server.routers_beta.monitoring import router as monitoring_router
try:
    from server.routers_beta.github_mon import router as github_router
except ImportError:
    github_router=None
try:
    from server.routers_beta.chat_mon  import router as chat_router
except ImportError:
    chat_router=None
try:
    from server.routers_beta.sla_mon   import router as sla_router
except ImportError:
    sla_router=None

app = FastAPI(title="kobong-api-beta", version="β")


app.include_router(gh_hook.router, prefix='/api/mon/github', tags=['github'])
app.include_router(chat_feed.router, prefix='/api/mon/chat', tags=['chat'])
app.add_middleware(CORSMiddleware,
    allow_origins=["http://localhost:5173","http://127.0.0.1:5173","*"],
    allow_methods=["*"], allow_headers=["*"])

app.include_router(monitoring_router, prefix="/api/mon", tags=["monitoring"])
if github_router: app.include_router(github_router, prefix="/api/mon/github", tags=["github"])
if chat_router:   app.include_router(chat_router,   prefix="/api/mon", tags=["chat"])
if sla_router:    app.include_router(sla_router,    prefix="/api/mon", tags=["sla"])

@app.get("/")

def root(): return {"ok": True, "service": "kobong-api-beta"}