from backend.app.ai.contracts import AIIntelligenceResponse
from backend.app.ai.models import EduTwinState, LearningState, MindTraceInput
from backend.app.ai.orchestrator import AIOrchestrator

def make_answer(student_answer):
    return MindTraceInput(concept="Factorization",question="Factorize x^2 + 5x + 6",correct_answer="(x + 2)(x + 3)",student_answer=student_answer)

def make_twin():
    return EduTwinState(student_id="demo-student",concept_id="factorization",concept="Factorization",mastery=0.58,confidence=0.62,learning_state=LearningState.DEVELOPING)

def test_orchestrator_runs_full_loop_without_gemini():
    diagnosis,twin,path=AIOrchestrator(use_gemini=False).analyze_and_recommend(answer=make_answer("(x + 1)(x + 6)"),twin=make_twin())
    assert diagnosis.misconception_code=="incorrect_factor_pair"
    assert twin.active_misconception=="incorrect_factor_pair"
    assert path.action.value=="targeted_practice"

def test_orchestrator_falls_back_when_gemini_is_unavailable(monkeypatch):
    monkeypatch.setenv("EDUOS_AI_PROVIDER","gemini")
    monkeypatch.delenv("GEMINI_API_KEY",raising=False)
    diagnosis,_,_=AIOrchestrator().analyze_and_recommend(answer=make_answer("(x + 1)(x + 6)"),twin=make_twin())
    assert diagnosis.model_name=="deterministic-mvp"

def test_api_contract_mapping_is_structured():
    diagnosis,twin,path=AIOrchestrator(use_gemini=False).analyze_and_recommend(answer=make_answer("(x + 1)(x + 6)"),twin=make_twin())
    data=AIIntelligenceResponse(mindtrace=diagnosis,edutwin=twin,pathai=path).to_api_data(analysis_id="analysis-1",recommendation_id="recommendation-1")
    assert data["analysis_id"]=="analysis-1"
    assert data["misconception"]["title"]=="Incorrect factor pair"
    assert data["recommendation"]["action"]=="targeted_practice"
    assert "learning_twin" in data
