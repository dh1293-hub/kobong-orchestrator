from __future__ import annotations
import asyncio, math, os, random, time
from typing import Callable, Awaitable, TypeVar, ParamSpec
import httpx

P = ParamSpec("P"); R = TypeVar("R")

def _env_int(name: str, default: int) -> int:
    try: return int(os.getenv(name, default))
    except Exception: return default

ATTEMPTS = _env_int("KOBONG_RETRY_ATTEMPTS", 3)
BACKOFF_MS = _env_int("KOBONG_RETRY_BACKOFF_MS", 200)
FACTOR = _env_int("KOBONG_RETRY_BACKOFF_FACTOR", 2)
MAX_BACKOFF_MS = _env_int("KOBONG_RETRY_MAX_BACKOFF_MS", 5_000)
JITTER_MS = _env_int("KOBONG_RETRY_JITTER_MS", 150)

def _sleep_ms(ms: int):
    time.sleep(ms/1000)

def _next_sleep(attempt: int) -> int:
    base = min(MAX_BACKOFF_MS, int(BACKOFF_MS * (FACTOR ** (attempt-1))))
    return max(0, base + random.randint(0, JITTER_MS))

def retry(fn: Callable[P, R]) -> Callable[P, R]:
    def wrap(*args: P.args, **kwargs: P.kwargs) -> R:
        last_exc = None
        for i in range(1, ATTEMPTS+1):
            try: return fn(*args, **kwargs)
            except Exception as e:
                last_exc = e
                if i >= ATTEMPTS: break
                _sleep_ms(_next_sleep(i))
        raise last_exc  # type: ignore
    return wrap

def aretry(fn: Callable[P, Awaitable[R]]) -> Callable[P, Awaitable[R]]:
    async def wrap(*args: P.args, **kwargs: P.kwargs) -> R:
        last_exc = None
        for i in range(1, ATTEMPTS+1):
            try: return await fn(*args, **kwargs)
            except Exception as e:
                last_exc = e
                if i >= ATTEMPTS: break
                await asyncio.sleep(_next_sleep(i)/1000)
        raise last_exc  # type: ignore
    return wrap

class HttpClient:
    def __init__(self, **kw): self._kw = kw
    @retry
    def get(self, url: str, **kw): 
        with httpx.Client(**self._kw) as c: return c.get(url, **kw)
    @retry
    def post(self, url: str, **kw): 
        with httpx.Client(**self._kw) as c: return c.post(url, **kw)
    @aretry
    async def aget(self, url: str, **kw):
        async with httpx.AsyncClient(**self._kw) as c: return await c.get(url, **kw)
    @aretry
    async def apost(self, url: str, **kw):
        async with httpx.AsyncClient(**self._kw) as c: return await c.post(url, **kw)