from pydantic import BaseModel, Field

class ConceptMastery(BaseModel):
    concept_id: str
    name: str
    mastery: float = Field(ge=0, le=100)
    status: str

class LearningTwinResponse(BaseModel):
    student_id: str
    overall_mastery: float = Field(ge=0, le=100)
    concepts: list[ConceptMastery]
