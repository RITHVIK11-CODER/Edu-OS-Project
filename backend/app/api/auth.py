from fastapi import APIRouter, Depends
from app.api.dependencies import get_current_user
from app.schemas.auth import AuthResponse, LoginRequest, RegisterRequest, UserResponse
from app.services.auth import login, register

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=AuthResponse)
async def login_endpoint(payload: LoginRequest):
    return await login(payload.email, payload.password)

@router.post("/register", response_model=AuthResponse)
async def register_endpoint(payload: RegisterRequest):
    return await register(payload.email, payload.password, payload.display_name)

@router.get("/me", response_model=UserResponse)
async def me(current_user: dict = Depends(get_current_user)):
    return current_user
