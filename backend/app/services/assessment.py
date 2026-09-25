from fastapi import HTTPException
from app.database.supabase import supabase
from app.services.student import student_for_user

def _attempt(attempt_id:str, user_id:str)->dict:
    student=student_for_user(user_id)
    rows=(supabase.table("assessment_attempts").select("id, assessment_id, student_id, status, started_at, submitted_at, score").eq("id",attempt_id).eq("student_id",student["id"]).limit(1).execute()).data or []
    if not rows: raise HTTPException(status_code=404,detail="Attempt not found")
    return rows[0]

def start(assessment_id:str,user_id:str)->dict:
    student=student_for_user(user_id)
    existing=(supabase.table("assessment_attempts").select("id,status,started_at").eq("assessment_id",assessment_id).eq("student_id",student["id"]).eq("status","IN_PROGRESS").limit(1).execute()).data or []
    if existing:return {"attempt_id":existing[0]["id"],"status":existing[0]["status"],"started_at":existing[0]["started_at"]}
    assessment=(supabase.table("assessments").select("id,status").eq("id",assessment_id).limit(1).execute()).data or []
    if not assessment: raise HTTPException(status_code=404,detail="Assessment not found")
    row=(supabase.table("assessment_attempts").insert({"assessment_id":assessment_id,"student_id":student["id"]}).execute()).data
    if not row: raise HTTPException(status_code=503,detail="Could not create attempt")
    return {"attempt_id":row[0]["id"],"status":row[0]["status"],"started_at":row[0]["started_at"]}

def questions(assessment_id:str,user_id:str)->list[dict]:
    # Verify the student has an active attempt for this assessment before exposing questions.
    student=student_for_user(user_id)
    attempts=(supabase.table("assessment_attempts").select("id").eq("assessment_id",assessment_id).eq("student_id",student["id"]).eq("status","IN_PROGRESS").limit(1).execute()).data or []
    if not attempts: raise HTTPException(status_code=403,detail="Start the assessment first")
    rows=(supabase.table("assessment_questions").select("question_id,sequence,questions(id,concept_id,question_text,question_type,options,difficulty)").eq("assessment_id",assessment_id).order("sequence").execute()).data or []
    return [r["questions"] for r in rows if r.get("questions")]

def answer(attempt_id:str,payload:dict,user_id:str)->dict:
    attempt=_attempt(attempt_id,user_id)
    if attempt["status"]!="IN_PROGRESS": raise HTTPException(status_code=409,detail="Attempt is no longer active")
    q=(supabase.table("questions").select("id").eq("id",payload["question_id"]).limit(1).execute()).data or []
    if not q: raise HTTPException(status_code=404,detail="Question not found")
    membership=(supabase.table("assessment_questions").select("question_id").eq("assessment_id",attempt["assessment_id"]).eq("question_id",payload["question_id"]).limit(1).execute()).data or []
    if not membership: raise HTTPException(status_code=400,detail="Question does not belong to this assessment")
    row={"attempt_id":attempt_id,"question_id":payload["question_id"],"answer":payload["student_answer"],"time_spent_seconds":payload.get("time_taken_seconds")}
    existing=(supabase.table("assessment_answers").select("id").eq("attempt_id",attempt_id).eq("question_id",payload["question_id"]).limit(1).execute()).data or []
    if existing:
        return {"answer_id":existing[0]["id"],"status":"UPDATED"}
    created=(supabase.table("assessment_answers").insert(row).execute()).data or []
    if not created: raise HTTPException(status_code=503,detail="Could not save answer")
    return {"answer_id":created[0]["id"],"status":"SAVED"}

def submit(attempt_id:str,user_id:str)->dict:
    attempt=_attempt(attempt_id,user_id)
    if attempt["status"]!="IN_PROGRESS": return {"attempt_id":attempt_id,"status":attempt["status"],"score":attempt.get("score")}
    rows=(supabase.table("assessment_answers").select("id,question_id,answer,questions(correct_answer)").eq("attempt_id",attempt_id).execute()).data or []
    if not rows: raise HTTPException(status_code=400,detail="No answers submitted")
    correct=0
    for row in rows:
        expected=(row.get("questions") or {}).get("correct_answer")
        actual=row.get("answer")
        ok=str(actual).strip().lower()==str(expected).strip().lower() if not isinstance(expected,(dict,list)) else actual==expected
        correct+=1 if ok else 0
        supabase.table("assessment_answers").update({"is_correct":ok}).eq("id",row["id"]).execute()
    total_rows=(supabase.table("assessment_questions").select("question_id").eq("assessment_id",attempt["assessment_id"]).execute()).data or []
    total=len(total_rows)
    if total == 0: raise HTTPException(status_code=503,detail="Assessment has no questions")
    score=round(correct*100/total,2)
    supabase.table("assessment_attempts").update({"status":"SUBMITTED","submitted_at":datetime.now(timezone.utc).isoformat(),"score":score}).eq("id",attempt_id).execute()
    return {"attempt_id":attempt_id,"status":"SUBMITTED","score":score,"correct_answers":correct,"total_questions":total}

def result(attempt_id:str,user_id:str)->dict:
    attempt=_attempt(attempt_id,user_id)
    rows=(supabase.table("assessment_answers").select("is_correct").eq("attempt_id",attempt_id).execute()).data or []
    question_rows=(supabase.table("assessment_questions").select("question_id").eq("assessment_id",attempt["assessment_id"]).execute()).data or []
    return {"attempt_id":attempt_id,"status":attempt["status"],"score":attempt.get("score"),"correct_answers":sum(1 for r in rows if r.get("is_correct") is True),"total_questions":len(question_rows)}
