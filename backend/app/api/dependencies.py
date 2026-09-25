from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.database.supabase import supabase


bearer_scheme = HTTPBearer(auto_error=False)


def _unauthorized(detail: str = "Authentication required") -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=detail,
        headers={"WWW-Authenticate": "Bearer"},
    )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict:
    """Validate a Supabase access token and resolve the application user."""
    if credentials is None:
        raise _unauthorized()

    try:
        auth_response = supabase.auth.get_user(credentials.credentials)
        auth_user = getattr(auth_response, "user", None)
        if auth_user is None:
            raise _unauthorized("Invalid or expired token")

        response = (
            supabase.table("users")
            .select("id, auth_user_id, role, display_name")
            .eq("auth_user_id", str(auth_user.id))
            .limit(1)
            .execute()
        )
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        ) from exc

    rows = response.data or []
    if not rows:
        raise _unauthorized("Application user not found")

    return rows[0]


async def require_teacher(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user.get("role") != "TEACHER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Teacher role required",
        )
    return current_user
