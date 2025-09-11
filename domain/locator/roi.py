"""
Project : ChatGPT5 AI Link – Conductor
Module  : domain/locator/roi.py
Version : v0.1.0 (2025-09-10 23:40)
Summary : ROI Anchor helper (좌표/해상도 보정)
Author  : GPT-5 (협업: 한민수)
"""
from typing import Tuple

class ROIAnchor:
    def __init__(self, x: int, y: int, w: int, h: int, base_res: Tuple[int, int] = (1920, 1080)):
        self.x, self.y, self.w, self.h = x, y, w, h
        self.base_res = base_res

    def scale_to(self, target_res: Tuple[int, int]) -> Tuple[int, int, int, int]:
        bx, by = self.base_res
        tx, ty = target_res
        sx, sy = tx / bx, ty / by
        return (int(self.x * sx), int(self.y * sy), int(self.w * sx), int(self.h * sy))
