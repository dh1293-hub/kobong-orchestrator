# AUTO-GENERATED SHIM — fallback demo_state
import os
from functools import lru_cache
@lru_cache
def is_demo() -> bool:
    return os.getenv("KOBONG_DEMO","0").strip().lower() in ("1","true","yes","y","on")