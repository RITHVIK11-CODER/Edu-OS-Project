import pytest
from pydantic import ValidationError
from app.schemas.auth import UserResponse
from app.schemas.assessment import AnswerCreate

def test_user_requires_role():
    with pytest.raises(ValidationError):
        UserResponse(id="u",email="student@example.com",display_name="Student")

def test_user_accepts_only_real_application_roles():
    for role in ("STUDENT","TEACHER","PARENT","PRINCIPAL","ADMIN"):
        user=UserResponse(id="u",email="student@example.com",display_name="User",role=role)
        assert user.role==role

def test_answer_rejects_negative_time():
    with pytest.raises(ValidationError):
        AnswerCreate(question_id="q1",student_answer="x=2",time_taken_seconds=-1)

def test_answer_accepts_valid_payload():
    value=AnswerCreate(question_id="q1",student_answer="(x + 2)(x + 3)",time_taken_seconds=42)
    assert value.question_id=="q1"
    assert value.time_taken_seconds==42
