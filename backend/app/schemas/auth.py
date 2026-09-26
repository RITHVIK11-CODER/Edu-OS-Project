from typing import Literal
from pydantic import BaseModel, EmailStr
Role=Literal["STUDENT","TEACHER","PARENT","PRINCIPAL","ADMIN"]
class UserResponse(BaseModel):
    id:str
    email:EmailStr
    display_name:str|None=None
    role:Role
