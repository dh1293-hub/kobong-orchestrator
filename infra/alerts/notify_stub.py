import os, sys

_LEVELS = ["TRACE","DEBUG","INFO","WARN","ERROR","FATAL"]

def notify(level: str, record: dict) -> None:
    try:
        min_level = os.getenv("ALERT_MIN_LEVEL", "ERROR").upper()
        if _LEVELS.index(level) < _LEVELS.index(min_level):
            return
    except Exception:
        return
    sink = os.getenv("ALERT_SINK", "console")
    if sink == "console":
        print("[ALERT]", level, "-", record.get("message",""), file=sys.stderr)
