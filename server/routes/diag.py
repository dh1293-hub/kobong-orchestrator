# ------------------------------------------------------------
# server/routes/diag.py  (unprotected echo for diagnostics)
# ------------------------------------------------------------
from fastapi import APIRouter, Request
router = APIRouter(prefix="/diag", tags=["diag"])

@router.get("/echo")
@router.post("/echo")
async def echo(request: Request):
    body = await request.body()
    # Lowercased headers snapshot
    headers = {k.lower(): v for k, v in request.headers.items()}
    return {
        "method": request.method,
        "path": str(request.url.path),
        "headers": headers,
        "body": body.decode("utf-8", errors="ignore"),
    }