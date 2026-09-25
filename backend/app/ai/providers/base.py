from typing import Protocol
from ..models import MindTraceInput, MindTraceResult

class LLMProvider(Protocol):
    name: str
    def analyze_mindtrace(self, data: MindTraceInput) -> MindTraceResult: ...
