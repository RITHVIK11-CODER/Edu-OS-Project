from backend.app.ai.edutwin import EduTwinEngine
from backend.app.ai.mindtrace import MindTraceEngine
from backend.app.ai.models import EduTwinState, LearningState, MasteryEvidence, MindTraceInput, PathAIInput
from backend.app.ai.pathai import PathAIEngine

def test_mindtrace_factor_pair():
    r=MindTraceEngine().analyze(MindTraceInput(concept="Factorization",question="Factorize x^2 + 5x + 6",correct_answer="(x + 2)(x + 3)",student_answer="(x + 1)(x + 6)"))
    assert not r.is_correct and r.misconception_code=="incorrect_factor_pair" and r.recommended_action.value=="targeted_practice"

def test_mindtrace_correct():
    r=MindTraceEngine().analyze(MindTraceInput(concept="Factorization",question="Factorize x^2 + 5x + 6",correct_answer="(x + 2)(x + 3)",student_answer="(x + 2)(x + 3)"))
    assert r.is_correct and r.recommended_action.value=="advance_to_next_concept"

def test_mindtrace_empty():
    r=MindTraceEngine().analyze(MindTraceInput(concept="Factorization",question="Factorize x^2 + 5x + 6",correct_answer="(x + 2)(x + 3)",student_answer=""))
    assert r.misconception_code=="conceptual_gap" and r.confidence<1

def test_edutwin_update():
    state=EduTwinState(student_id="demo",concept_id="factorization",concept="Factorization",mastery=.58,confidence=.62,learning_state=LearningState.DEVELOPING)
    updated=EduTwinEngine().update(state,MasteryEvidence(correct=False,diagnosis_confidence=.91,misconception_code="incorrect_factor_pair",evidence="Incorrect factor pair."))
    assert 0<=updated.mastery<=1 and updated.mastery<state.mastery and updated.active_misconception=="incorrect_factor_pair" and updated.learning_state==LearningState.NEEDS_PRACTICE

def test_pathai_targeted_practice():
    r=PathAIEngine().recommend(PathAIInput(concept="Factorization",mastery=.41,confidence=.87,active_misconception="incorrect_factor_pair"))
    assert r.action.value=="targeted_practice" and r.question_count==3

def test_pathai_advance():
    r=PathAIEngine().recommend(PathAIInput(concept="Quadratic Equations",mastery=.90,confidence=.90))
    assert r.action.value=="advance_to_next_concept"
