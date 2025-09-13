from typing import Protocol

class SnapshotPort(Protocol):
    def capture(self, label: str | None = None) -> str:
        """Capture screenshot; return saved path."""
        ...
