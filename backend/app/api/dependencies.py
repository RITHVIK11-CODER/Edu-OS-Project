from collections.abc import Callable
from typing import Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from app.database.supabase import get_authenticated_client
bearer_scheme = HTTPBearer(auto_error=False)
ALLOWED_ROLES = frozenset({"STUDENT","TEACHER","PARENT","PRINCIPAL","ADMIN"})
def _unauthorized(detail="Authentication required"): return HTTPException(status_code=401,detail=detail,headers={"WWW-Authenticate":"Bearer"})
async def get_current_user(credentials: HTTPAuthorizationCredentials|None=Depends(bearer_scheme))->dict[str,Any]:
    if credentials is None: raise _unauthorized()
    token=credentials.credentials
    try:
        client=get_authenticated_client(token)
        auth_user=getattr(client.auth.get_user(token),"user",None)
        if auth_user is None: raise _unauthorized("Invalid or expired Supabase session")
        rows=(client.table("users").select("id,auth_user_id,role,display_name").eq("auth_user_id",str(auth_user.id)).limit(2).execute()).data or []
    except HTTPException: raise
    except Exception as exc: raise HTTPException(status_code=503,detail="Authentication service unavailable") from exc
    if len(rows)!=1: raise _unauthorized("Application user mapping is missing or invalid")
    user=rows[0]
    if user.get("role") not in ALLOWED_ROLES: raise HTTPException(status_code=500,detail="Invalid application role configuration")
    return {"id":user["id"],"auth_user_id":user["auth_user_id"],"email":auth_user.email,"display_name":user.get("display_name"),"role":user["role"]}
def require_role(*allowed_roles:str)->Callable[...,Any]:
    required=frozenset(allowed_roles)
    if not required.issubset(ALLOWED_ROLES): raise ValueError(f"Unsupported roles: {sorted(required-ALLOWED_ROLES)}")
    async def dependency(current_user:dict[str,Any]=Depends(get_current_user))->dict[str,Any]:
        if current_user["role"] not in required: raise HTTPException(status_code=403,detail="Insufficient role permissions")
        return current_user
    return dependency
def require_roles(*allowed_roles:str)->Callable[...,Any]: return require_role(*allowed_roles)
require_student=require_role("STUDENT")
require_teacher=require_role("TEACHER")
require_parent=require_role("PARENT")
require_principal=require_role("PRINCIPAL")
require_admin=require_role("ADMIN")
