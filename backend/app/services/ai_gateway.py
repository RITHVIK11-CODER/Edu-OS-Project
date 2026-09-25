from __future__ import annotations
from fastapi import HTTPException


def _orchestrator():
    try:
        from app.ai.orchestrator import AIOrchestrator
    except ImportError as exc:
        raise HTTPException(status_code=503, detail="AI learning engine is not integrated") from exc
    return AIOrchestrator()


def analyze(*, concept: str, question: str, correct_answer: str, student_answer: str, reasoning: str | None, student_id: str, concept_id: str, mastery: float, confidence: float):
    try:
        from app.ai.models import MindTraceInput, EduTwinState
        input_data=MindTraceInput(concept=concept,question=question,correct_answer=correct_answer,student_answer=student_answer,reasoning=reasoning)
        twin=EduTwinState(student_id=student_id,concept_id=concept_id,concept=concept,mastery=max(0,min(1,mastery/100)),confidence=max(0,min(1,confidence)))
        return _orchestrator().analyze_and_recommend(answer=input_data,twin=twin)
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(status_code=503, detail="AI analysis unavailable") from exc
