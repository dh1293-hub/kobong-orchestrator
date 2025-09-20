from fastapi import FastAPI
from .routes.diag import router as diag_router
from .routes.secure import router as secure_router
from .middleware.hmac_auth import HMACAuthMiddleware

app = FastAPI()
app.include_router(diag_router)

secure_app = FastAPI()
secure_app.add_middleware(HMACAuthMiddleware)
secure_app.include_router(secure_router)

app.mount("/secure", secure_app)
