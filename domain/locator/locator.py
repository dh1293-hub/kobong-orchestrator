"""
Project : ChatGPT5 AI Link – Conductor
Module  : domain/locator/locator.py
Version : v0.1.1 (2025-09-10 22:30)
Summary : Universal Locator v1 (OCR + Icon template)
Author  : GPT-5 (협업: 한민수)
Notes   : Contract-first; ROI/앵커 추후 보강 예정
"""

from pathlib import Path
from typing import Optional, Tuple

import cv2
import numpy as np

# OCR은 시스템에 Tesseract가 없으면 건너뛰도록 선택적 임포트
try:
    import pytesseract  # type: ignore
    _HAS_TESS = True
except Exception:
    _HAS_TESS = False


class LocatorResult:
    def __init__(self, found: bool, score: float, roi: Optional[Tuple[int, int, int, int]] = None):
        self.found = found
        self.score = score
        self.roi = roi

    def __repr__(self) -> str:
        return f"LocatorResult(found={self.found}, score={self.score:.2f}, roi={self.roi})"


class UniversalLocator:
    def __init__(self, lang: str = "kor+eng"):
        self.lang = lang

    # OCR 기반 탐지 (Tesseract 미설치 시 found=False 반환)
    def locate_text(self, image: np.ndarray, query: str) -> LocatorResult:
        if not _HAS_TESS:
            return LocatorResult(False, 0.0, None)
        try:
            text = pytesseract.image_to_string(image, lang=self.lang)
        except Exception:
            return LocatorResult(False, 0.0, None)
        if query.lower() in text.lower():
            return LocatorResult(True, 1.0, None)
        return LocatorResult(False, 0.0, None)

    # 아이콘 기반 탐지 (템플릿 매칭)
    def locate_icon(self, image: np.ndarray, template_path: Path, threshold: float = 0.8) -> LocatorResult:
        p = Path(template_path)
        if not p.exists():
            raise FileNotFoundError(p)

        template = cv2.imread(str(p), cv2.IMREAD_GRAYSCALE)
        if template is None:
            raise ValueError(f"failed to read template: {p}")

        if image.ndim == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image

        res = cv2.matchTemplate(gray, template, cv2.TM_CCOEFF_NORMED)
        _, max_val, _, max_loc = cv2.minMaxLoc(res)

        if float(max_val) >= threshold:
            h, w = template.shape[:2]
            roi = (int(max_loc[0]), int(max_loc[1]), int(w), int(h))
            return LocatorResult(True, float(max_val), roi)
        return LocatorResult(False, float(max_val), None)
