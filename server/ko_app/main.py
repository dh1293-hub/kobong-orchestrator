from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from server.routersfrom  import router as monitoring_router
from server.routersfrom  import router as github_router
from server.routersfrom  import router as chat_router

app = FastAPI(title="kobong-api", version="0.1")
app.add_middleware(CORSMiddleware,
    allow_origins=["http://localhost:5173","http://127.0.0.1:5173","*"],
    allow_methods=["*"], allow_headers=["*"])

app.include_router(monitoring_router, prefix="/api/mon", tags=["monitoring"])
app.include_router(github_router,     prefix="/api/mon/github", tags=["monitoring"])
app.include_router(chat_router,       prefix="/api/mon", tags=["monitoring"])

@app.get("/")

def root():
    return {"ok": True, "service": "kobong-api"}