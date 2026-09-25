from fastapi import HTTPException
from app.database.supabase import supabase

def student_for_user(user_id: str) -> dict:
    rows=(supabase.table("students").select("id, grade, section, school_id").eq("user_id",user_id).limit(1).execute()).data or []
    if not rows: raise HTTPException(status_code=404, detail="Student profile not found")
    return rows[0]

def learning_twin(user_id: str) -> dict:
    student=student_for_user(user_id)
    rows=(supabase.table("student_mastery").select("concept_id, mastery_score, concepts(name)").eq("student_id",student["id"]).execute()).data or []
    concepts=[]
    for row in rows:
        name=(row.get("concepts") or {}).get("name") or "Unknown"
        score=float(row.get("mastery_score") or 0)
        status="STRONG" if score>=80 else "DEVELOPING" if score>=60 else "WEAK"
        concepts.append({"concept_id":row["concept_id"],"name":name,"mastery":score,"status":status})
    overall=round(sum(x["mastery"] for x in concepts)/len(concepts),2) if concepts else 0.0
    return {"student_id":student["id"],"overall_mastery":overall,"concepts":concepts}
