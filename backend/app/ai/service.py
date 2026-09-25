"""Orchestration boundary for MindTrace -> EduTwin -> PathAI."""
from .edutwin import EduTwinEngine
from .mindtrace import MindTraceEngine
from .models import EduTwinState,MasteryEvidence,MindTraceInput,PathAIInput,PathAIRecommendation
from .pathai import PathAIEngine
class LearningIntelligenceService:
    def __init__(self):self.mindtrace=MindTraceEngine();self.edutwin=EduTwinEngine();self.pathai=PathAIEngine()
    def process_answer(self,*,mindtrace_input:MindTraceInput,edutwin_state:EduTwinState,prerequisite_mastery:dict[str,float]|None=None):
        diagnosis=self.mindtrace.analyze(mindtrace_input)
        updated=self.edutwin.update(edutwin_state,MasteryEvidence(correct=diagnosis.is_correct,diagnosis_confidence=diagnosis.confidence,misconception_code=None if diagnosis.is_correct else diagnosis.misconception_code,evidence=diagnosis.evidence[0] if diagnosis.evidence else None))
        recommendation=self.pathai.recommend(PathAIInput(concept=updated.concept,mastery=updated.mastery,confidence=updated.confidence,active_misconception=updated.active_misconception,prerequisite_mastery=prerequisite_mastery or {}))
        return diagnosis,updated,recommendation
