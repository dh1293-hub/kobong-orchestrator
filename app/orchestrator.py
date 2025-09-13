from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict
from datetime import datetime, timezone
import time

from domain.ports import LocatorPort, UiPort, OcrPort, SnapshotPort, ClockPort, Point

@dataclass(slots=True)
class Ports:
    locator: LocatorPort
    ui: UiPort
    ocr: OcrPort
    snapshot: SnapshotPort
    clock: ClockPort

@dataclass
class _Ctx:
    ids: Dict[str, Dict[str, Any]] = field(default_factory=dict)

def _now() -> str:
    return datetime.now(timezone.utc).isoformat()

def _as_point(target: Any, ctx: _Ctx) -> Point:
    if isinstance(target, str) and target.startswith("@"):
        k = target[1:]
        p = ctx.ids.get(k, {}).get("point")
        if not p:
            raise KeyError(f"pointer not found: {target}")
        return p
    if isinstance(target, (list, tuple)) and len(target) == 2:
        return Point(float(target[0]), float(target[1]))
    raise ValueError(f"invalid target: {target!r}")

def _derive_status(actions_out: list[dict]) -> str:
    # 하나라도 fail이면 fail, 아니면 ok
    return "fail" if any(a.get("status") == "fail" for a in actions_out) else "ok"

class ActionOrchestrator:
    def __init__(self, ports: Ports):
        self.ports = ports

    def run(self, plan: Dict[str, Any]) -> Dict[str, Any]:
        started = _now()
        t0 = time.perf_counter()
        steps_out: list[dict] = []
        ctx = _Ctx()

        for step in plan.get("steps", []):
            step_t0 = time.perf_counter()
            actions_out: list[dict] = []

            for a in step.get("actions", []):
                op = a.get("op")
                try:
                    if op == "LOCATE":
                        point, ev = self.ports.locator.locate(
                            by=a["by"],
                            query=a.get("query"),
                            area=tuple(a["area"]) if a.get("area") else None,
                            score_threshold=a.get("score_threshold"),
                            template_id=a.get("template_id"),
                        )
                        if (id_ := a.get("id")):
                            ctx.ids[id_] = {"point": point}
                        actions_out.append({"op":"LOCATE","id":a.get("id"),"status":"ok","evidence":{"locate":ev}})
                    elif op == "FOCUS":
                        self.ports.ui.focus(_as_point(a["target"], ctx))
                        actions_out.append({"op":"FOCUS","status":"ok"})
                    elif op == "PASTE":
                        self.ports.ui.paste(a["text"], bool(a.get("clear", False)))
                        actions_out.append({"op":"PASTE","status":"ok"})
                    elif op == "TYPE":
                        self.ports.ui.type_text(a["text"])
                        actions_out.append({"op":"TYPE","status":"ok"})
                    elif op == "PRESS":
                        self.ports.ui.press(a["keys"])
                        actions_out.append({"op":"PRESS","status":"ok"})
                    elif op == "WAIT":
                        self.ports.clock.sleep_ms(int(a["ms"]))
                        actions_out.append({"op":"WAIT","status":"ok"})
                    elif op == "VERIFY":
                        ok = True
                        if "ocr_contains" in a:
                            txt = self.ports.ocr.read(None)
                            q = a["ocr_contains"]
                            if isinstance(q, list):
                                ok = all(s in txt for s in q)
                            else:
                                ok = str(q) in txt
                        actions_out.append({"op":"VERIFY","status":"ok" if ok else "fail"})
                    elif op == "SNAPSHOT":
                        path = self.ports.snapshot.capture(a.get("label"))
                        actions_out.append({"op":"SNAPSHOT","status":"ok","evidence":{"snapshots":[path]}})
                    elif op == "CLICK":
                        self.ports.ui.click(_as_point(a["target"], ctx), a.get("button","left"), a.get("offset"))
                        actions_out.append({"op":"CLICK","status":"ok"})
                    elif op == "DOUBLE":
                        self.ports.ui.double(_as_point(a["target"], ctx))
                        actions_out.append({"op":"DOUBLE","status":"ok"})
                    elif op == "DRAG":
                        self.ports.ui.drag(_as_point(a["from"], ctx), _as_point(a["to"], ctx))
                        actions_out.append({"op":"DRAG","status":"ok"})
                    elif op == "SCROLL":
                        self.ports.ui.scroll(int(a["amount"]), a.get("axis","vertical"))
                        actions_out.append({"op":"SCROLL","status":"ok"})
                    elif op == "NAVIGATE":
                        self.ports.ui.navigate(a["url"])
                        actions_out.append({"op":"NAVIGATE","status":"ok"})
                    else:
                        actions_out.append({"op":op,"status":"skipped"})
                except Exception as e:
                    actions_out.append({"op":op,"status":"fail","error":{"code":"ACTION_FAIL","message":str(e)}})
                    break

            step_status = _derive_status(actions_out)
            steps_out.append({
                "step": step.get("step", 0),
                "status": step_status,
                "duration_ms": int((time.perf_counter()-step_t0)*1000),
                "actions": actions_out,
            })

        # 전체 결과: fail이 하나도 없으면 ok
        all_ok = not any(a.get("status") == "fail" for s in steps_out for a in s["actions"])
        out = {
            "version": "0.3",
            "plan_id": plan.get("plan_id","unknown"),
            "started_at": started,
            "finished_at": _now(),
            "duration_ms": int((time.perf_counter()-t0)*1000),
            "outcome": "ok" if all_ok else "partial",
            "steps": steps_out
        }
        return out

