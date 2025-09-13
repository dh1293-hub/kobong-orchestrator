from typing import Protocol, Literal, Iterable, Optional
from .types import Point

By = Literal["text", "icon", "anchor", "coord"]

class LocatorPort(Protocol):
    def locate(
        self,
        by: By,
        query: Optional[str | Iterable[str]] = None,
        area: Optional[tuple[float, float, float, float]] = None,
        score_threshold: float | None = None,
        template_id: str | None = None,
    ) -> tuple[Point, dict]:
        """
        Returns (point, evidence).
        evidence may include {"strategy": str, "score": float, ...}
        """
        ...
