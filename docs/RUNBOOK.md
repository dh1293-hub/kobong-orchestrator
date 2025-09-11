# RUNBOOK (v0.1)
Startup: check_import.bat → run_ui.bat
Approval: HITL gates on sensitive actions (login/upload/delete).
Evidence: logs/ JSONL + snapshots/ per step; rotate/retain per policy.
Rollback: feature flags off; return to last stable build (one-click script).


