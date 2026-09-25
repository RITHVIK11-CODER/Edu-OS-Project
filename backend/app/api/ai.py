from fastapi import APIRouter, Depends
from app.api.dependencies import get_current_user
from app.database.supabase import supabase
from app.schemas.ai import MindTraceRequest, PathAIRequest
from app.services.student import student_for_user
from app.services.ai_gateway import analyze

router=APIRouter(tags=["AI Learning"])

def _answer(answer_id:str,user_id:str):
    student=student_for_user(user_id)
    rows=(supabase.table("assessment_answers").select("id,attempt_id,question_id,answer,is_correct,assessment_attempts!inner(student_id),questions(id,concept_id,question_text,correct_answer,concepts(name))").eq("id",answer_id).eq("assessment_attempts.student_id",student["id"]).limit(1).execute()).data or []
    if not rows: return None
    return rows[0],student

@router.post("/mindtrace/analyze")
async def mindtrace(payload:MindTraceRequest,current_user:dict=Depends(get_current_user)):
    found=_answer(payload.answer_id,current_user["id"])
    if not found: return {"success":False,"error":{"code":"NOT_FOUND","message":"Answer not found"}}
    row,student=found
    q=row.get("questions") or {}; concept=(q.get("concepts") or {}).get("name") or "Factorization"
    mastery_rows=(supabase.table("student_mastery").select("mastery_score,confidence").eq("student_id",student["id"]).eq("concept_id",q.get("concept_id")).limit(1).execute()).data or []
    mastery=float(mastery_rows[0].get("mastery_score") or 0) if mastery_rows else 0
    confidence=float(mastery_rows[0].get("confidence") or .5) if mastery_rows else .5
    diagnosis,twin,recommendation=analyze(concept=concept,question=q.get("question_text", ""),correct_answer=str(q.get("correct_answer","")),student_answer=str(row.get("answer") or ""),reasoning=None,student_id=student["id"],concept_id=str(q.get("concept_id")),mastery=mastery,confidence=confidence)
    saved=(supabase.table("mindtrace_analyses").insert({"assessment_answer_id":payload.answer_id,"misconception_code":diagnosis.misconception_code,"misconception_label":diagnosis.misconception_label,"root_cause":diagnosis.root_cause,"evidence":"; ".join(diagnosis.evidence),"confidence":diagnosis.confidence,"model_name":diagnosis.model_name,"prompt_version":diagnosis.prompt_version}).execute()).data or []
    analysis_id=saved[0]["id"] if saved else ""
    return {"success":True,"data":{"analysis_id":analysis_id,"is_correct":diagnosis.is_correct,"concept":{"id":diagnosis.concept_id,"name":concept},"misconception":{"title":diagnosis.misconception.title,"description":diagnosis.misconception.description,"root_concept_id":diagnosis.misconception.root_concept_id,"confidence":diagnosis.confidence},"recommended_action":recommendation.action.value,"recommendation":{"action":recommendation.action.value,"reason":recommendation.reason,"difficulty":recommendation.difficulty,"question_count":recommendation.question_count,"steps":recommendation.steps},"learning_twin":twin.model_dump()}}

@router.post("/pathai/recommend")
async def pathai(payload:PathAIRequest,current_user:dict=Depends(get_current_user)):
    student=student_for_user(current_user["id"])
    rows=(supabase.table("student_mastery").select("mastery_score,confidence,concepts(name)").eq("student_id",student["id"]).eq("concept_id",payload.concept_id).limit(1).execute()).data or []
    if not rows:return {"success":False,"error":{"code":"NOT_FOUND","message":"Concept mastery not found"}}
    row=rows[0]; concept=(row.get("concepts") or {}).get("name") or "Factorization"
    _,_,recommendation=analyze(concept=concept,question="",correct_answer="",student_answer="",reasoning=None,student_id=student["id"],concept_id=payload.concept_id,mastery=float(row.get("mastery_score") or 0),confidence=float(row.get("confidence") or .5))
    return {"success":True,"data":{"recommendation_id":None,"concept_id":payload.concept_id,"action":recommendation.action.value,"reason":recommendation.reason,"duration_minutes":5,"steps":recommendation.steps}}
