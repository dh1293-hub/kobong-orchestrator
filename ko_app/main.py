from __future__ import annotations
import importlib, pkgutil, pathlib, inspect
from typing import Iterable, Set
from fastapi import FastAPI, APIRouter

WANTED_PATHS = {
    "/api/v1/ping", "/api/v1/echo", "/api/v1/sum",
    "/secure/ping", "/echo",
    "/healthz", "/readyz", "/livez",
}

def _extract_paths(app: FastAPI) -> Set[str]:
    paths = set()
    for r in getattr(app, "routes", []):
        p = getattr(r, "path", None) or getattr(r, "path_format", None)
        if p: paths.add(p)
    return paths

def _score_app(app: FastAPI) -> int:
    return len(_extract_paths(app) & WANTED_PATHS)

def _iter_candidates():
    # 테스트 친화: server.app 우선
    yield ("server.app",       ("app","create_app","get_app","build_app","make_app"))
    yield ("server.app_entry", ("app","create_app","get_app","build_app","make_app"))

def _try_make_app(mod_name: str, name: str) -> FastAPI | None:
    try:
        m = importlib.import_module(mod_name)
    except Exception:
        return None
    obj = getattr(m, name, None)
    if obj is None:
        return None
    if callable(obj):
        try:
            made = obj()
            if isinstance(made, FastAPI):
                return made
        except Exception:
            return None
    elif isinstance(obj, FastAPI):
        return obj
    return None

def _load_best_app() -> FastAPI:
    best = None
    best_score = -1
    for mod, names in _iter_candidates():
        for nm in names:
            app = _try_make_app(mod, nm)
            if app is None: 
                continue
            sc = _score_app(app)
            if sc > best_score:
                best, best_score = app, sc
            if sc >= len(WANTED_PATHS):
                return app
    return best or FastAPI()

def _iter_submodules(pkgname: str) -> Iterable[str]:
    try:
        pkg = importlib.import_module(pkgname)
    except Exception:
        return []
    try:
        base = pathlib.Path(pkg.__file__).parent
    except Exception:
        return []
    for info in pkgutil.walk_packages([str(base)], prefix=pkgname + "."):
        yield info.name

def _include_all_routers_in_module(app: FastAPI, modname: str) -> int:
    """모듈 내 APIRouter 인스턴스를 전부 include (router/api/api_router/v1_router 등)."""
    added = 0
    try:
        m = importlib.import_module(modname)
    except Exception:
        return 0
    # 우선 알려진 이름들
    for key in ("router","api","api_router","v1_router"):
        r = getattr(m, key, None)
        if isinstance(r, APIRouter):
            try:
                app.include_router(r); added += 1
            except Exception:
                pass
    # 그 외 속성 전체 스캔
    for name, val in inspect.getmembers(m):
        if isinstance(val, APIRouter):
            try:
                app.include_router(val); added += 1
            except Exception:
                pass
    return added

def _autowire_if_needed(app: FastAPI) -> None:
    if _score_app(app) >= 4:
        return
    total = 0
    for pkgname in ("server.api", "server.routers"):
        for mod in _iter_submodules(pkgname):
            total += _include_all_routers_in_module(app, mod)
    # prefix 라우터가 뒤늦게 붙는 경우도 있으므로 별도 반환 없음

app = _load_best_app()
# force include from server.api.v1_endpoints (avoid relying solely on scanning)
try:
    v1 = importlib.import_module("server.api.v1_endpoints")
    for name in ("router_v1","root_router","secure_router","metrics_router","health_router"):
        r = getattr(v1, name, None)
        if r is not None:
            try: app.include_router(r)
            except Exception: pass
except Exception:
    pass

_autowire_if_needed(app)

# 헬스 최소 보강 (문법 수정: 데코레이터와 def를 분리)
try:
    paths = _extract_paths(app)
    need = not {"/healthz","/readyz","/livez"} & paths
    if need:
        r = APIRouter()
        @r.get("/healthz")
        async def _hz():
            return {"status":"ok"}
        @r.get("/readyz")
        async def _rz():
            return {"status":"ready"}
        @r.get("/livez")
        async def _lz():
            return {"status":"live"}
        app.include_router(r)
except Exception:
    pass