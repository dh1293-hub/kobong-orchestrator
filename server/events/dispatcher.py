from __future__ import annotations
from typing import Callable, Dict, Any
from ..utils.masking import mask
from ..metrics import hooks

Handler = Callable[[dict], None]
_registry: Dict[str, Handler] = {}

def on(event_type: str):
    def deco(fn: Handler) -> Handler:
        _registry[event_type.upper()] = fn
        return fn
    return deco

def dispatch(evt: dict) -> None:
    et = (evt.get("type") or "unknown").upper()
    data = mask(evt.get("data"))
    hooks.emit("event.total", 1, {"type": et})
    (_registry.get(et) or _default)(data)

def _default(data: dict) -> None:
    hooks.emit("event.unhandled", 1, {})

# --- Stubs ---
@on("USER_SIGNED_IN")
def _on_user_signed_in(data: dict) -> None:
    hooks.emit("event.user_signed_in", 1, {})
    # TODO: add business logic

@on("PAYMENT_SUCCEEDED")

def _on_payment_ok(data: dict) -> None:
    hooks.emit("event.payment_succeeded", 1, {})
    # TODO: add business logic