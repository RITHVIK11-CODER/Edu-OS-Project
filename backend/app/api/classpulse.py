from fastapi import APIRouter, Depends

from app.api.dependencies import require_teacher
from app.schemas.classpulse import (
    ClassAnalytics,
    ClassSummary,
    ConceptInsight,
    MisconceptionInsight,
    RecommendationCreate,
    RecommendationResponse,
    StudentInsight,
)
from app.services.classpulse import (
    create_recommendation,
    get_analytics,
    get_attention,
    get_concepts,
    get_misconceptions,
    get_students,
    list_classes,
)

router = APIRouter(prefix="/teacher", tags=["ClassPulse"])


@router.get("/classes", response_model=dict)
async def teacher_classes(current_user: dict = Depends(require_teacher)):
    data = list_classes(current_user["id"])
    return {"success": True, "data": [item.model_dump() for item in data]}


@router.get("/classes/{class_id}/analytics", response_model=dict)
async def class_analytics(
    class_id: str,
    current_user: dict = Depends(require_teacher),
):
    data = get_analytics(class_id, current_user["id"])
    return {"success": True, "data": data.model_dump()}


@router.get("/classes/{class_id}/concepts", response_model=dict)
async def class_concepts(
    class_id: str,
    current_user: dict = Depends(require_teacher),
):
    data: list[ConceptInsight] = get_concepts(class_id, current_user["id"])
    return {"success": True, "data": [item.model_dump() for item in data]}


@router.get("/classes/{class_id}/students", response_model=dict)
async def class_students(
    class_id: str,
    current_user: dict = Depends(require_teacher),
):
    data: list[StudentInsight] = get_students(class_id, current_user["id"])
    return {"success": True, "data": [item.model_dump() for item in data]}


@router.get("/classes/{class_id}/attention", response_model=dict)
async def class_attention(
    class_id: str,
    current_user: dict = Depends(require_teacher),
):
    data: list[StudentInsight] = get_attention(class_id, current_user["id"])
    return {"success": True, "data": [item.model_dump() for item in data]}


@router.get("/classes/{class_id}/misconceptions", response_model=dict)
async def class_misconceptions(
    class_id: str,
    current_user: dict = Depends(require_teacher),
):
    data: list[MisconceptionInsight] = get_misconceptions(
        class_id, current_user["id"]
    )
    return {"success": True, "data": [item.model_dump() for item in data]}


@router.post(
    "/classes/{class_id}/recommendation",
    response_model=dict,
    status_code=201,
)
async def class_recommendation(
    class_id: str,
    payload: RecommendationCreate,
    current_user: dict = Depends(require_teacher),
):
    data: RecommendationResponse = create_recommendation(
        class_id,
        current_user["id"],
        payload,
    )
    return {"success": True, "data": data.model_dump()}
