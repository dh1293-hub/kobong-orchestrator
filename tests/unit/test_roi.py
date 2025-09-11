from domain.locator.roi import ROIAnchor

def test_roi_scaling():
    roi = ROIAnchor(100, 200, 300, 400, base_res=(1920, 1080))
    assert roi.scale_to((3840, 2160)) == (200, 400, 600, 800)
