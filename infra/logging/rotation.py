import os
import time

def rotate_if_needed(path: str, max_bytes: int, backups: int) -> None:
    if max_bytes <= 0 or backups <= 0:
        return
    try:
        if os.path.exists(path) and os.path.getsize(path) >= max_bytes:
            base = path
            for i in range(backups - 1, 0, -1):
                s = f"{base}.{i}"
                d = f"{base}.{i+1}"
                if os.path.exists(s):
                    if os.path.exists(d):
                        os.remove(d)
                    os.replace(s, d)
            d1 = f"{base}.1"
            if os.path.exists(d1):
                os.remove(d1)
            os.replace(base, d1)
    except Exception:
        pass

def cleanup_by_age(path: str, days: int) -> None:
    if days <= 0:
        return
    cutoff = time.time() - days * 86400
    d = os.path.dirname(path) or "."
    base = os.path.basename(path)
    for name in os.listdir(d):
        if name == base or name.startswith(base + "."):
            p = os.path.join(d, name)
            try:
                if os.path.getmtime(p) < cutoff:
                    os.remove(p)
            except Exception:
                pass
