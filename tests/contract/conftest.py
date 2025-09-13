# conftest.py — add repo paths so `infra.logging.json_logger` can be imported in CI
# Intent: Locate the directory that contains the "infra" package and prepend it to sys.path for tests.
# Safe: test-scope only; no runtime effect on production code.

import sys, pathlib

def _candidate_roots(repo_root: pathlib.Path):
    # common roots
    yield repo_root
    yield repo_root / "src"
    yield repo_root / "tools" / "kobong_logger_cli"
    yield repo_root / "tools" / "kobong_logger_cli" / "src"
    # dynamic discovery by walking once
    try:
        for p in repo_root.rglob("infra/logging/json_logger.py"):
            # parent of "infra"
            yield p.parents[2]
    except Exception:
        pass

def pytest_sessionstart(session):
    repo_root = pathlib.Path(__file__).resolve().parents[2]  # <repo> / tests / contract / conftest.py
    added = False
    for root in _candidate_roots(repo_root):
        try:
            if not root or not root.exists():
                continue
            infra_dir = root / "infra"
            if infra_dir.exists() and (infra_dir / "logging").exists():
                sys.path.insert(0, str(root))
                added = True
                break
        except Exception:
            continue
    if not added:
        # help the logs: show where we looked
        sys.stderr.write(f"[conftest] infra package root not found. tried under: {repo_root}\n")
