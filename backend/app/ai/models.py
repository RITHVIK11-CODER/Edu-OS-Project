"""Typed contracts shared by MindTrace, EduTwin and PathAI."""
from __future__ import annotations
from enum import Enum
from typing import Any
from pydantic import BaseModel, Field, field_validator

class LearningAction(str, Enum):
    REVIEW_CONCEPT="review_concept"
    WORKED_EXAMPLE="worked_example"
    TARGETED_PRACTICE="targeted_practice"
    PREREQUISITE_REVIEW="prerequisite_review"
    REASSESSMENT="reassessment"
    ADVANCE_TO_NEXT_CONCEPT="advance_to_next_concept"

class LearningState(str, Enum):
    NEEDS_REVIEW="needs_review"
    NEEDS_PRACTICE="needs_practice"
    DEVELOPING="developing"
    READY_TO_REASSESS="ready_to_reassess"
    MASTERED="mastered"

class MindTraceInput(BaseModel):
    grade:int=Field(default=10,ge=10,le=10)
    subject:str=Field(default="Mathematics",min_length=1,max_length=80)
    concept:str=Field(min_length=1,max_length=120)
    question:str=Field(min_length=1,max_length=4000)
    correct_answer:str=Field(min_length=1,max_length=2000)
    student_answer:str=Field(default="",max_length=2000)
    reasoning:str|None=Field(default=None,max_length=4000)
    recent_relevant_mistakes:list[str]=Field(default_factory=list,max_length=10)
    learning_context:dict[str,Any]=Field(default_factory=dict)
    @field_validator("subject")
    @classmethod
    def validate_subject(cls,value:str)->str:
        if value.strip().lower()!="mathematics": raise ValueError("MVP MindTrace supports Grade 10 Mathematics only")
        return value.strip()

class Misconception(BaseModel):
    title:str
    description:str
    root_concept_id:str
    confidence:float=Field(ge=0.0,le=1.0)

class MindTraceResult(BaseModel):
    is_correct:bool
    concept_id:str
    misconception_code:str
    misconception_label:str
    root_cause:str
    evidence:list[str]=Field(min_length=1,max_length=5)
    confidence:float=Field(ge=0.0,le=1.0)
    misconception:Misconception
    recommended_action:LearningAction
    model_name:str="deterministic-mvp"
    prompt_version:str="mindtrace_v1"

class EduTwinState(BaseModel):
    student_id:str
    concept_id:str
    concept:str
    mastery:float=Field(ge=0.0,le=1.0)
    confidence:float=Field(ge=0.0,le=1.0)
    active_misconception:str|None=None
    learning_state:LearningState
    recent_evidence:list[str]=Field(default_factory=list,max_length=10)

class MasteryEvidence(BaseModel):
    correct:bool
    diagnosis_confidence:float=Field(default=0.0,ge=0.0,le=1.0)
    misconception_code:str|None=None
    evidence:str|None=None
    practice_score:float|None=Field(default=None,ge=0.0,le=1.0)

class PathAIInput(BaseModel):
    concept:str
    mastery:float=Field(ge=0.0,le=1.0)
    confidence:float=Field(ge=0.0,le=1.0)
    active_misconception:str|None=None
    recent_performance:list[float]=Field(default_factory=list,max_length=10)
    prerequisite_mastery:dict[str,float]=Field(default_factory=dict)

class PathAIRecommendation(BaseModel):
    action:LearningAction
    concept:str
    reason:str
    difficulty:str=Field(pattern=r"^(easy|medium|hard)$")
    question_count:int=Field(ge=0,le=10)
    steps:list[str]=Field(default_factory=list,max_length=6)
