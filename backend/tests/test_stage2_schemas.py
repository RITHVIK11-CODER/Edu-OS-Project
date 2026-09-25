import pytest
from pydantic import ValidationError
from app.schemas.auth import LoginRequest, RegisterRequest
from app.schemas.assessment import AnswerCreate


def test_login_requires_password():
    with pytest.raises(ValidationError):
        LoginRequest(email="student@example.com", password="")


def test_register_rejects_privileged_role():
    with pytest.raises(ValidationError):
        RegisterRequest(email="student@example.com", password="password123", display_name="Student", role="ADMIN")


def test_answer_rejects_negative_time():
    with pytest.raises(ValidationError):
        AnswerCreate(question_id="q1", student_answer="x=2", time_taken_seconds=-1)


def test_answer_accepts_valid_payload():
    value=AnswerCreate(question_id="q1", student_answer="(x + 2)(x + 3)", time_taken_seconds=42)
    assert value.question_id == "q1"
    assert value.time_taken_seconds == 42
