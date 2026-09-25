from pydantic import ValidationError
import pytest

from app.schemas.classpulse import RecommendationCreate


def test_recommendation_requires_title():
    with pytest.raises(ValidationError):
        RecommendationCreate(title="")


def test_recommendation_rejects_invalid_priority():
    with pytest.raises(ValidationError):
        RecommendationCreate(title="Revision", priority=6)


def test_recommendation_accepts_valid_payload():
    payload = RecommendationCreate(
        concept_id="concept-1",
        title="Factorization revision",
        description="Targeted revision session",
        reason="Repeated misconception pattern",
        priority=2,
        student_ids=["student-1"],
    )

    assert payload.title == "Factorization revision"
    assert payload.priority == 2
