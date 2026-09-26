from fastapi import APIRouter, Depends
from app.api.dependencies import get_current_user, require_student
from app.services.student import student_for_user, learning_twin

router=APIRouter(prefix="/students",tags=["Students"])

@router.get("/me")
async def me(current_user:dict=Depends(require_student)):
    return {"success":True,"data":{**student_for_user(current_user["id"]),"user_id":current_user["id"],"display_name":current_user.get("display_name")}}

@router.get("/me/learning-twin")
async def my_learning_twin(current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":learning_twin(current_user["id"])}

@router.get("/me/progress")
async def progress(current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":learning_twin(current_user["id"])}
