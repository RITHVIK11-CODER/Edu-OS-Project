from collections import defaultdict
from typing import Any

from fastapi import HTTPException, status

from app.database.supabase import supabase
from app.schemas.classpulse import (
    ClassAnalytics,
    ClassSummary,
    ConceptInsight,
    MisconceptionInsight,
    RecommendationCreate,
    RecommendationResponse,
    StudentInsight,
)


ATTENTION_MASTERY_THRESHOLD = 60.0
MAX_LIST_RESULTS = 500


def _rows(response: Any) -> list[dict]:
    return list(response.data or [])


def _round(value: float, digits: int = 2) -> float:
    return round(float(value), digits)


def _teacher_id(user_id: str) -> str:
    response = (
        supabase.table("teachers")
        .select("id")
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    rows = _rows(response)
    if not rows:
        raise HTTPException(status_code=404, detail="Teacher profile not found")
    return rows[0]["id"]


def _class_for_teacher(class_id: str, user_id: str) -> dict:
    teacher_id = _teacher_id(user_id)
    response = (
        supabase.table("teacher_class_memberships")
        .select("class_id")
        .eq("class_id", class_id)
        .eq("teacher_id", teacher_id)
        .limit(1)
        .execute()
    )
    if not _rows(response):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Teacher is not assigned to this class",
        )

    response = (
        supabase.table("classes")
        .select("id, name, grade, section, academic_year")
        .eq("id", class_id)
        .limit(1)
        .execute()
    )
    rows = _rows(response)
    if not rows:
        raise HTTPException(status_code=404, detail="Class not found")
    return rows[0]


def _class_students(class_id: str) -> list[dict]:
    response = (
        supabase.table("class_memberships")
        .select("student_id")
        .eq("class_id", class_id)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    return _rows(response)


def _student_profiles(student_ids: list[str]) -> dict[str, dict]:
    if not student_ids:
        return {}
    response = (
        supabase.table("students")
        .select("id, user_id")
        .in_("id", student_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    profiles = _rows(response)
    user_ids = [row["user_id"] for row in profiles if row.get("user_id")]
    users: dict[str, dict] = {}
    if user_ids:
        user_response = (
            supabase.table("users")
            .select("id, display_name")
            .in_("id", user_ids)
            .limit(MAX_LIST_RESULTS)
            .execute()
        )
        users = {row["id"]: row for row in _rows(user_response)}

    return {
        row["id"]: {
            "id": row["id"],
            "display_name": users.get(row.get("user_id"), {}).get("display_name"),
        }
        for row in profiles
    }


def list_classes(user_id: str) -> list[ClassSummary]:
    teacher_id = _teacher_id(user_id)
    memberships = _rows(
        supabase.table("teacher_class_memberships")
        .select("class_id")
        .eq("teacher_id", teacher_id)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    class_ids = [row["class_id"] for row in memberships]
    if not class_ids:
        return []

    classes = _rows(
        supabase.table("classes")
        .select("id, name, grade, section, academic_year")
        .in_("id", class_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    counts = defaultdict(int)
    for row in _class_students_for_classes(class_ids):
        counts[row["class_id"]] += 1

    return [
        ClassSummary(**row, student_count=counts[row["id"]])
        for row in classes
    ]


def _class_students_for_classes(class_ids: list[str]) -> list[dict]:
    return _rows(
        supabase.table("class_memberships")
        .select("class_id, student_id")
        .in_("class_id", class_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )


def _mastery_for_students(student_ids: list[str]) -> list[dict]:
    if not student_ids:
        return []
    return _rows(
        supabase.table("student_mastery")
        .select("student_id, concept_id, mastery_score, confidence, updated_at")
        .in_("student_id", student_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )


def _concepts(concept_ids: list[str]) -> dict[str, dict]:
    if not concept_ids:
        return {}
    rows = _rows(
        supabase.table("concepts")
        .select("id, name")
        .in_("id", concept_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    return {row["id"]: row for row in rows}


def _misconceptions(student_ids: list[str]) -> list[dict]:
    if not student_ids:
        return []

    attempts = _rows(
        supabase.table("assessment_attempts")
        .select("id, student_id")
        .in_("student_id", student_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    attempt_ids = [row["id"] for row in attempts]
    if not attempt_ids:
        return []

    answers = _rows(
        supabase.table("assessment_answers")
        .select("id, attempt_id")
        .in_("attempt_id", attempt_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )
    answer_ids = [row["id"] for row in answers]
    if not answer_ids:
        return []

    analyses = _rows(
        supabase.table("mindtrace_analyses")
        .select("assessment_answer_id, misconception_code, misconception_label")
        .in_("assessment_answer_id", answer_ids)
        .limit(MAX_LIST_RESULTS)
        .execute()
    )

    attempt_student = {row["id"]: row["student_id"] for row in attempts}
    answer_attempt = {row["id"]: row["attempt_id"] for row in answers}
    result = []
    for row in analyses:
        result.append(
            {
                **row,
                "student_id": attempt_student.get(
                    answer_attempt.get(row["assessment_answer_id"])
                ),
            }
        )
    return result


def get_analytics(class_id: str, user_id: str) -> ClassAnalytics:
    _class_for_teacher(class_id, user_id)
    student_rows = _class_students(class_id)
    student_ids = [row["student_id"] for row in student_rows]

    mastery_rows = _mastery_for_students(student_ids)
    concept_map = _concepts([row["concept_id"] for row in mastery_rows])

    student_scores: dict[str, list[float]] = defaultdict(list)
    concept_scores: dict[str, list[float]] = defaultdict(list)
    concept_affected: dict[str, set[str]] = defaultdict(set)

    for row in mastery_rows:
        score = float(row.get("mastery_score") or 0)
        student_scores[row["student_id"]].append(score)
        concept_scores[row["concept_id"]].append(score)
        if score < ATTENTION_MASTERY_THRESHOLD:
            concept_affected[row["concept_id"]].add(row["student_id"])

    all_scores = [score for scores in student_scores.values() for score in scores]
    average_mastery = _round(sum(all_scores) / len(all_scores)) if all_scores else 0.0

    weak_concepts = sorted(
        (
            ConceptInsight(
                concept_id=concept_id,
                name=concept_map.get(concept_id, {}).get("name", "Unknown concept"),
                mastery=_round(sum(scores) / len(scores)),
                affected_students=len(concept_affected[concept_id]),
            )
            for concept_id, scores in concept_scores.items()
        ),
        key=lambda item: item.mastery,
    )[:5]

    attention_count = sum(
        1
        for student_id in student_ids
        if student_scores.get(student_id)
        and sum(student_scores[student_id]) / len(student_scores[student_id])
        < ATTENTION_MASTERY_THRESHOLD
    )

    misconception_rows = _misconceptions(student_ids)
    by_label: dict[tuple[str | None, str], dict] = {}
    for row in misconception_rows:
        label = row.get("misconception_label") or "Unspecified misconception"
        key = (row.get("misconception_code"), label)
        item = by_label.setdefault(
            key,
            {"count": 0, "students": set()},
        )
        item["count"] += 1
        if row.get("student_id"):
            item["students"].add(row["student_id"])

    common_misconceptions = sorted(
        (
            MisconceptionInsight(
                code=code,
                label=label,
                occurrence_count=item["count"],
                affected_students=len(item["students"]),
            )
            for (code, label), item in by_label.items()
        ),
        key=lambda item: item.occurrence_count,
        reverse=True,
    )[:5]

    return ClassAnalytics(
        class_id=class_id,
        students=len(student_ids),
        average_mastery=average_mastery,
        weak_concepts=weak_concepts,
        attention_count=attention_count,
        common_misconceptions=common_misconceptions,
    )


def get_concepts(class_id: str, user_id: str) -> list[ConceptInsight]:
    analytics = get_analytics(class_id, user_id)
    return analytics.weak_concepts


def get_students(class_id: str, user_id: str) -> list[StudentInsight]:
    _class_for_teacher(class_id, user_id)
    student_rows = _class_students(class_id)
    student_ids = [row["student_id"] for row in student_rows]
    profiles = _student_profiles(student_ids)
    mastery_rows = _mastery_for_students(student_ids)

    by_student: dict[str, list[float]] = defaultdict(list)
    weak_counts: dict[str, int] = defaultdict(int)
    for row in mastery_rows:
        score = float(row.get("mastery_score") or 0)
        by_student[row["student_id"]].append(score)
        if score < ATTENTION_MASTERY_THRESHOLD:
            weak_counts[row["student_id"]] += 1

    result = []
    for student_id in student_ids:
        scores = by_student.get(student_id, [])
        result.append(
            StudentInsight(
                student_id=student_id,
                display_name=profiles.get(student_id, {}).get("display_name"),
                mastery=_round(sum(scores) / len(scores)) if scores else 0.0,
                weak_concept_count=weak_counts[student_id],
            )
        )
    return sorted(result, key=lambda item: item.mastery)


def get_attention(class_id: str, user_id: str) -> list[StudentInsight]:
    return [
        student
        for student in get_students(class_id, user_id)
        if student.mastery < ATTENTION_MASTERY_THRESHOLD
    ]


def get_misconceptions(
    class_id: str,
    user_id: str,
) -> list[MisconceptionInsight]:
    return get_analytics(class_id, user_id).common_misconceptions


def create_recommendation(
    class_id: str,
    user_id: str,
    payload: RecommendationCreate,
) -> RecommendationResponse:
    _class_for_teacher(class_id, user_id)
    class_student_ids = {
        row["student_id"] for row in _class_students(class_id)
    }

    target_student_ids = payload.student_ids or sorted(class_student_ids)
    if not set(target_student_ids).issubset(class_student_ids):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Recommendation contains students outside the assigned class",
        )

    if not target_student_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Class has no students",
        )

    rows = [
        {
            "student_id": student_id,
            "concept_id": payload.concept_id,
            "recommendation_type": "CLASS_INTERVENTION",
            "title": payload.title,
            "description": payload.description,
            "reason": payload.reason,
            "priority": payload.priority,
            "status": "PENDING",
        }
        for student_id in target_student_ids
    ]

    response = (
        supabase.table("recommendations")
        .insert(rows)
        .select("id")
        .execute()
    )
    created = _rows(response)
    if len(created) != len(rows):
        raise HTTPException(
            status_code=500,
            detail="Recommendation persistence failed",
        )

    return RecommendationResponse(
        recommendation_id=created[0]["id"],
        student_ids=target_student_ids,
        concept_id=payload.concept_id,
        title=payload.title,
        description=payload.description,
        reason=payload.reason,
        priority=payload.priority,
    )
