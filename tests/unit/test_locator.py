import shutil
import cv2
import numpy as np
import pytest
from domain.locator.locator import UniversalLocator

TESS_PRESENT = shutil.which("tesseract") is not None

@pytest.mark.skipif(not TESS_PRESENT, reason="tesseract not installed")
def test_text_detection_basic():
    # 흰 배경에 "Send" 텍스트 합성
    img = np.ones((100, 300, 3), dtype=np.uint8) * 255
    cv2.putText(img, "Send", (50, 60), cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 0), 3)
    locator = UniversalLocator(lang="eng")
    result = locator.locate_text(img, "Send")
    assert result.found is True
    assert result.score == 1.0

def test_icon_detection(tmp_path):
    # 단순 사각형을 템플릿/원본에 동시에 그림
    img = np.ones((120, 120, 3), dtype=np.uint8) * 255
    cv2.rectangle(img, (30, 40), (70, 80), (0, 0, 0), -1)
    tpl = img[40:80, 30:70]
    tpl_path = tmp_path / "template.png"
    cv2.imwrite(str(tpl_path), tpl)

    locator = UniversalLocator()
    result = locator.locate_icon(img, tpl_path, threshold=0.75)

    assert result.found is True
    assert result.score >= 0.75
    assert result.roi is not None
