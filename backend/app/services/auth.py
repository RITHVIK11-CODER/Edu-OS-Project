from fastapi import HTTPException, status
from app.database.supabase import supabase

async def login(email: str, password: str) -> dict:
    try:
        response = supabase.auth.sign_in_with_password({"email": email, "password": password})
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password") from exc
    session = getattr(response, "session", None)
    auth_user = getattr(response, "user", None)
    if session is None or auth_user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    rows = (supabase.table("users").select("id, role, display_name").eq("auth_user_id", str(auth_user.id)).limit(1).execute()).data or []
    if not rows:
        raise HTTPException(status_code=401, detail="Application user not found")
    return {"access_token": session.access_token, "refresh_token": getattr(session, "refresh_token", None), "token_type": "bearer", "user": rows[0]}

async def register(email: str, password: str, display_name: str) -> dict:
    try:
        response = supabase.auth.sign_up({"email": email, "password": password})
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Registration failed") from exc
    auth_user = getattr(response, "user", None)
    if auth_user is None:
        raise HTTPException(status_code=400, detail="Registration failed")
    try:
        row = {"auth_user_id": str(auth_user.id), "role": "STUDENT", "display_name": display_name.strip()}
        created = supabase.table("users").insert(row).execute()
        user = (created.data or [row])[0]
    except Exception as exc:
        raise HTTPException(status_code=503, detail="Application user creation failed") from exc
    session = getattr(response, "session", None)
    return {"access_token": session.access_token if session else "", "refresh_token": getattr(session, "refresh_token", None) if session else None, "token_type": "bearer", "user": user}
