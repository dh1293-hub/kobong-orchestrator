"""
Project : ChatGPT5 AI Link – Conductor
Module  : domain/dsl/actions.py
Version : v0.1.0 (2025-09-10 23:40)
Summary : Action DSL v0.3 실행기 (LOCATE → PASTE → VERIFY; stub)
Author  : GPT-5 (협업: 한민수)
"""
from typing import Dict, Any, List
import numpy as np
from domain.locator.locator import UniversalLocator, LocatorResult

class ActionExecutor:
    def __init__(self):
        self.locator = UniversalLocator()

    def run(self, dsl: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        results: List[Dict[str, Any]] = []
        for step in dsl:
            action = list(step.keys())[0]
            params = step[action]

            if action == "LOCATE":
                img = params.get("image")
                query = params.get("query")
                if isinstance(img, np.ndarray) and isinstance(query, str):
                    res: LocatorResult = self.locator.locate_text(img, query)
                    results.append({"action": "LOCATE", "found": res.found, "score": res.score})
                else:
                    results.append({"action": "LOCATE", "found": False, "score": 0.0})

            elif action == "PASTE":
                text = params.get("text")
                results.append({"action": "PASTE", "text": text, "status": "ok"})

            elif action == "VERIFY":
                text = params.get("ocr_contains")
                # PoC: 실제 OCR 미사용, 전달 텍스트 존재만 확인
                status = "ok" if text else "fail"
                results.append({"action": "VERIFY", "status": status})

            else:
                results.append({"action": action, "status": "stub"})
        return results
