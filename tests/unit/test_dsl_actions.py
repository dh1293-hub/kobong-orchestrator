import numpy as np
from domain.dsl.actions import ActionExecutor

def test_dsl_locate_paste_verify():
    img = np.ones((50, 100, 3), dtype=np.uint8) * 255
    dsl = [
        {"LOCATE": {"image": img, "query": "Hello"}},  # OCR stub: False도 허용
        {"PASTE": {"text": "Hello"}},
        {"VERIFY": {"ocr_contains": "Hello"}},
    ]
    ex = ActionExecutor()
    results = ex.run(dsl)
    assert any(r["action"] == "LOCATE" for r in results)
    assert any(r["action"] == "PASTE" and r["status"] == "ok" for r in results)
    assert any(r["action"] == "VERIFY" and r["status"] == "ok" for r in results)
