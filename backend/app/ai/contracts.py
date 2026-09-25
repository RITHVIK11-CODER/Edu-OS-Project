"""API-neutral DTO mapping for the stable EduOS AI contract."""
from __future__ import annotations
from pydantic import BaseModel
from .models import EduTwinState, MindTraceResult, PathAIRecommendation

class AIIntelligenceResponse(BaseModel):
    mindtrace: MindTraceResult
    edutwin: EduTwinState
    pathai: PathAIRecommendation

    def to_api_data(self, *, analysis_id: str | None = None, recommendation_id: str | None = None) -> dict:
        misconception = self.mindtrace.misconception.model_dump()
        return {
            "analysis_id": analysis_id,
            "is_correct": self.mindtrace.is_correct,
            "concept": {
                "id": self.mindtrace.concept_id,
                "name": self.edutwin.concept,
            },
            "misconception": {
                "title": misconception["title"],
                "description": misconception["description"],
                "root_concept_id": misconception["root_concept_id"],
                "confidence": misconception["confidence"],
            },
            "recommended_action": self.pathai.action.value,
            "recommendation": {
                "recommendation_id": recommendation_id,
                "action": self.pathai.action.value,
                "reason": self.pathai.reason,
                "difficulty": self.pathai.difficulty,
                "question_count": self.pathai.question_count,
                "steps": self.pathai.steps,
            },
            "learning_twin": self.edutwin.model_dump(),
        }
