from pydantic import BaseModel, Field

class MindTraceRequest(BaseModel):
    answer_id: str

class PathAIRequest(BaseModel):
    concept_id: str

class MindTraceResponse(BaseModel):
    analysis_id: str
    is_correct: bool
    concept: dict
    misconception: dict
    recommended_action: str
    recommendation: dict | None = None
    learning_twin: dict | None = None
