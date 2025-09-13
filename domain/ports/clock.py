from typing import Protocol

class ClockPort(Protocol):
    def sleep_ms(self, ms: int) -> None: ...
