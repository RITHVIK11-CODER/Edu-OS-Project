from pydantic import BaseModel, Field
from typing import Literal


class ClassSummary(BaseModel):
    id: str
    name: str | None = None
    grade: int | None = None
    section: str | None = None
    academic_year: str | None = None
    student_count: int = 0


class ConceptInsight(BaseModel):
    concept_id: str
    name: str
    mastery: float
    affected_students: int = 0


class StudentInsight(BaseModel):
    student_id: str
    display_name: str | None = None
    mastery: float
    weak_concept_count: int = 0


class MisconceptionInsight(BaseModel):
    code: str | None = None
    label: str
    occurrence_count: int
    affected_students: int


class ClassAnalytics(BaseModel):
    class_id: str
    students: int
    average_mastery: float
    weak_concepts: list[ConceptInsight] = Field(default_factory=list)
    attention_count: int
    common_misconceptions: list[MisconceptionInsight] = Field(default_factory=list)


class RecommendationCreate(BaseModel):
    concept_id: str | None = None
    title: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=2000)
    reason: str | None = Field(default=None, max_length=2000)
    priority: int = Field(default=1, ge=1, le=5)
    student_ids: list[str] = Field(default_factory=list)


class RecommendationResponse(BaseModel):
    recommendation_id: str
    student_ids: list[str]
    concept_id: str | None = None
    recommendation_type: Literal["CLASS_INTERVENTION"] = "CLASS_INTERVENTION"
    title: str
    description: str | None = None
    reason: str | None = None
    priority: int
