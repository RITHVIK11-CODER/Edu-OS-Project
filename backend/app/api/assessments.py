from fastapi import APIRouter, Depends
from app.api.dependencies import get_current_user
from app.schemas.assessment import AnswerCreate
from app.services import assessment

router=APIRouter(tags=["Assessments"])

@router.post("/assessments/{assessment_id}/start")
async def start(assessment_id:str,current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":assessment.start(assessment_id,current_user["id"])}

@router.get("/assessments/{assessment_id}/questions")
async def questions(assessment_id:str,current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":assessment.questions(assessment_id,current_user["id"])}

@router.post("/attempts/{attempt_id}/answers")
async def answer(attempt_id:str,payload:AnswerCreate,current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":assessment.answer(attempt_id,payload.model_dump(),current_user["id"])}

@router.post("/attempts/{attempt_id}/submit")
async def submit(attempt_id:str,current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":assessment.submit(attempt_id,current_user["id"])}

@router.get("/attempts/{attempt_id}/result")
async def result(attempt_id:str,current_user:dict=Depends(get_current_user)):
    return {"success":True,"data":assessment.result(attempt_id,current_user["id"])}
