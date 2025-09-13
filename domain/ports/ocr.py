from typing import Protocol, Optional

class OcrPort(Protocol):
    def read(self, region: Optional[tuple[float,float,float,float]] = None) -> str:
        """Return recognized text from region/window."""
        ...
