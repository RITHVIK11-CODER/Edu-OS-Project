from pydantic import BaseModel, Field

class AttemptStartResponse(BaseModel):
    attempt_id: str
    status: str
    started_at: str

class AnswerCreate(BaseModel):
    question_id: str
    student_answer: str = Field(max_length=4000)
    time_taken_seconds: int | None = Field(default=None, ge=0, le=86400)

class SubmitResponse(BaseModel):
    attempt_id: str
    status: str
    score: float | None = None

class QuestionResponse(BaseModel):
    id: str
    concept_id: str
    question_text: str
    question_type: str
    options: object | None = None
    difficulty: int | None = None

class ResultResponse(BaseModel):
    attempt_id: str
    status: str
    score: float | None = None
    correct_count: int
    total_questions: int
