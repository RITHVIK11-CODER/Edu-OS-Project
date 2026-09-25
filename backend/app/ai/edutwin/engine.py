"""Transparent mastery-state updates for the EduOS MVP."""
from __future__ import annotations
from ..models import EduTwinState, LearningState, MasteryEvidence

class EduTwinEngine:
    def update(self,state:EduTwinState,evidence:MasteryEvidence)->EduTwinState:
        previous=state.mastery
        assessment_score=1.0 if evidence.correct else 0.0
        practice_score=evidence.practice_score if evidence.practice_score is not None else assessment_score
        mastery=(.60*previous)+(.25*assessment_score)+(.15*practice_score)
        if not evidence.correct and evidence.diagnosis_confidence>=.85:
            mastery-=.05
        mastery=min(1.0,max(0.0,mastery))
        confidence=min(1.0,max(0.0,(.70*state.confidence)+(.30*evidence.diagnosis_confidence)))
        if mastery>=.85 and evidence.correct:
            learning_state=LearningState.MASTERED
        elif not evidence.correct:
            learning_state=LearningState.NEEDS_REVIEW if mastery<.25 else LearningState.NEEDS_PRACTICE
        elif mastery>=.65:
            learning_state=LearningState.READY_TO_REASSESS
        else:
            learning_state=LearningState.DEVELOPING
        return state.model_copy(update={"mastery":round(mastery,4),"confidence":round(confidence,4),"active_misconception":None if evidence.correct else evidence.misconception_code,"learning_state":learning_state,"recent_evidence":(state.recent_evidence+[evidence.evidence or ("Correct response." if evidence.correct else "Incorrect response.")])[-10:]})
