"""Evaluate the deterministic MindTrace MVP against the curated synthetic dataset."""
import json
from pathlib import Path
from backend.app.ai.mindtrace import MindTraceEngine
from backend.app.ai.models import MindTraceInput

DATASET=Path(__file__).resolve().parents[1]/"datasets"/"mindtrace_mvp.json"

def main():
    cases=json.loads(DATASET.read_text(encoding="utf-8"))
    engine=MindTraceEngine()
    rows=[]
    for c in cases:
        r=engine.analyze(MindTraceInput(grade=c["grade"],subject=c["subject"],concept=c["concept"],question=c["question"],correct_answer=c["correct_answer"],student_answer=c["student_answer"]))
        rows.append((c,r))
    total=len(rows)
    correctness=sum(r.is_correct==c["expected_correctness"] for c,r in rows)
    misconception=sum(r.misconception_code==c["expected_misconception"] for c,r in rows)
    action=sum(r.recommended_action.value==c["expected_action"] for c,r in rows)
    print(f"Cases tested: {total}")
    print(f"Structured validity: {total}/{total}")
    print(f"Correctness match: {correctness}/{total}")
    print(f"Misconception match: {misconception}/{total}")
    print(f"Action relevance: {action}/{total}")
    for c,r in rows:
        if r.misconception_code!=c["expected_misconception"] or r.recommended_action.value!=c["expected_action"]:
            print(f"FAIL {c['case_id']}: {r.misconception_code} / {r.recommended_action.value}")

if __name__=="__main__":
    main()
