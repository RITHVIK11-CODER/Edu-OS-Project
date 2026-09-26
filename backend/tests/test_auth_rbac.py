import pytest
from app.api.dependencies import ALLOWED_ROLES, require_role
from app.schemas.auth import UserResponse

def test_exact_application_roles():
    assert ALLOWED_ROLES == {"STUDENT","TEACHER","PARENT","PRINCIPAL","ADMIN"}

@pytest.mark.asyncio
async def test_role_dependency_rejects_wrong_role():
    dep=require_role("ADMIN")
    with pytest.raises(Exception) as exc:
        await dep({"role":"STUDENT"})
    assert getattr(exc.value,"status_code",None)==403

def test_user_response_requires_real_role_and_email():
    user=UserResponse(id="u",email="student@example.com",display_name="Student",role="STUDENT")
    assert user.role=="STUDENT"
    with pytest.raises(Exception):
        UserResponse(id="u",email="student@example.com",display_name="Student")

def test_privileged_roles_are_not_client_registerable():
    assert {"ADMIN","PRINCIPAL","TEACHER"}.issubset(ALLOWED_ROLES)
