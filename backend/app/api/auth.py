from fastapi import APIRouter, Depends
from app.api.dependencies import get_current_user
from app.schemas.auth import UserResponse
router = APIRouter(prefix="/auth", tags=["Authentication"])
@router.get("/me", response_model=UserResponse)
async def me(current_user: dict = Depends(get_current_user)): return current_user
