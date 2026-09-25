"""Backend-facing AI orchestration boundary for Developer 3 integration."""
from __future__ import annotations
import os
from .edutwin import EduTwinEngine
from .mindtrace import MindTraceEngine
from .models import EduTwinState, MasteryEvidence, MindTraceInput, PathAIInput
from .pathai import PathAIEngine
from .providers.gemini import GeminiProvider

class AIOrchestrator:
    """Runs the complete intelligence loop without owning HTTP/database concerns.

    Developer 3 supplies authorized domain data and persists the returned result.
    """

    def __init__(self, use_gemini: bool | None = None):
        self.deterministic = MindTraceEngine()
        self.edutwin = EduTwinEngine()
        self.pathai = PathAIEngine()
        self.provider = None
        enabled = (os.getenv("EDUOS_AI_PROVIDER", "deterministic").lower() == "gemini") if use_gemini is None else use_gemini
        key = os.getenv("GEMINI_API_KEY")
        if enabled and key:
            try:
                self.provider = GeminiProvider(key, os.getenv("GEMINI_MODEL", "gemini-1.5-flash"))
            except ValueError:
                self.provider = None

    def analyze_and_recommend(self, *, answer: MindTraceInput, twin: EduTwinState, prerequisite_mastery: dict[str, float] | None = None):
        diagnosis = self._diagnose(answer)
        updated_twin = self.edutwin.update(
            twin,
            MasteryEvidence(
                correct=diagnosis.is_correct,
                diagnosis_confidence=diagnosis.confidence,
                misconception_code=None if diagnosis.is_correct else diagnosis.misconception_code,
                evidence=diagnosis.evidence[0] if diagnosis.evidence else None,
            ),
        )
        recommendation = self.pathai.recommend(
            PathAIInput(
                concept=updated_twin.concept,
                mastery=updated_twin.mastery,
                confidence=updated_twin.confidence,
                active_misconception=updated_twin.active_misconception,
                prerequisite_mastery=prerequisite_mastery or {},
            )
        )
        return diagnosis, updated_twin, recommendation

    def _diagnose(self, answer: MindTraceInput):
        if self.provider is None:
            return self.deterministic.analyze(answer)
        try:
            return self.provider.analyze_mindtrace(answer)
        except (RuntimeError, ValueError, TypeError):
            # Provider failures must not corrupt the learning state.
            return self.deterministic.analyze(answer)
