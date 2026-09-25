"""MindTrace diagnosis with deterministic MVP rules."""
from __future__ import annotations
import re
from ..models import LearningAction,MindTraceInput,MindTraceResult,Misconception
from ..taxonomy import get_definition

class MindTraceEngine:
    MODEL_NAME="deterministic-mvp"
    PROMPT_VERSION="mindtrace_v1"
    def analyze(self,data:MindTraceInput)->MindTraceResult:
        answer=data.student_answer.strip()
        correct=self._normalize(answer)==self._normalize(data.correct_answer)
        concept_id=self._concept_id(data.concept)
        if correct:
            return MindTraceResult(is_correct=True,concept_id=concept_id,misconception_code="unknown",misconception_label="No misconception detected",root_cause="The submitted response matches the expected answer.",evidence=["Student answer matches the normalized expected answer."],confidence=.99,misconception=Misconception(title="No misconception detected",description="The response is consistent with the expected answer.",root_concept_id=concept_id,confidence=.99),recommended_action=LearningAction.ADVANCE_TO_NEXT_CONCEPT,model_name=self.MODEL_NAME,prompt_version=self.PROMPT_VERSION)
        code,evidence,confidence,action=self._classify_incorrect(data)
        definition=get_definition(code)
        description=self._diagnosis_description(code,data)
        return MindTraceResult(is_correct=False,concept_id=concept_id,misconception_code=code,misconception_label=definition.label,root_cause=definition.root_cause,evidence=evidence,confidence=confidence,misconception=Misconception(title=definition.label,description=description,root_concept_id=concept_id,confidence=confidence),recommended_action=action,model_name=self.MODEL_NAME,prompt_version=self.PROMPT_VERSION)
    def _classify_incorrect(self,data:MindTraceInput):
        answer=data.student_answer.strip(); lowered=answer.lower()
        if not answer:return "conceptual_gap",["No student answer was provided, so there is no solution evidence to inspect."],.94,LearningAction.REVIEW_CONCEPT
        if self._looks_like_sign_error(data):return "sign_error",["The response contains a sign pattern inconsistent with the expected result."],.90,LearningAction.WORKED_EXAMPLE
        if self._looks_like_factor_pair_error(data):return "incorrect_factor_pair",["The proposed factors do not reproduce the required product and/or middle term."],.91,LearningAction.TARGETED_PRACTICE
        if self._looks_incomplete(data):return "incomplete_factorization",["The response shows a partial factorization but does not finish the required form."],.87,LearningAction.TARGETED_PRACTICE
        if "formula" in lowered or "b²" in lowered or "b^2" in lowered:return "formula_misapplication",["The response references a quadratic formula step that does not match the supplied problem."],.73,LearningAction.WORKED_EXAMPLE
        if self._looks_arithmetic(data):return "arithmetic_error",["The response differs numerically from the expected result without enough evidence of a conceptual change."],.76,LearningAction.WORKED_EXAMPLE
        return "conceptual_gap",["The answer is incorrect and does not contain enough reliable structure for a narrower diagnosis."],.62,LearningAction.REVIEW_CONCEPT
    @staticmethod
    def _looks_like_factor_pair_error(data:MindTraceInput)->bool:
        a=re.findall(r"[-+]?\d+",data.student_answer); b=re.findall(r"[-+]?\d+",data.correct_answer)
        return bool(a and b and a!=b and len(a)>=2 and len(b)>=2)
    @staticmethod
    def _looks_like_sign_error(data:MindTraceInput)->bool:
        answer=data.student_answer.replace(" ",""); expected=data.correct_answer.replace(" ","")
        if "+" in expected and "-" in answer:return True
        if "-" in expected and "+" in answer:return True
        return False
    @staticmethod
    def _looks_incomplete(data:MindTraceInput)->bool:
        answer=data.student_answer.lower()
        return "..." in answer or ("x^2" in answer and "(" not in answer)
    @staticmethod
    def _looks_arithmetic(data:MindTraceInput)->bool:
        a=re.findall(r"(?<![a-zA-Z])[-+]?\d+(?:\.\d+)?",data.student_answer); b=re.findall(r"(?<![a-zA-Z])[-+]?\d+(?:\.\d+)?",data.correct_answer)
        return bool(a and b and len(a)==len(b))
    @staticmethod
    def _diagnosis_description(code:str,data:MindTraceInput)->str:
        descriptions={"incorrect_factor_pair":f"The response suggests an incorrect factor selection for {data.concept}.","sign_error":"The response suggests that a sign was handled incorrectly.","incomplete_factorization":"The response suggests that the factorization procedure was started but not completed.","arithmetic_error":"The response suggests a numerical calculation error rather than a clearly different concept.","formula_misapplication":"The response suggests that a formula was applied incorrectly to the problem.","conceptual_gap":"The available evidence suggests that the underlying concept needs review.","procedural_error":"The response suggests a procedural issue that needs additional evidence."}
        return descriptions.get(code,"The available evidence does not support a narrower diagnosis.")
    @staticmethod
    def _normalize(value:str)->str:return re.sub(r"\s+","",value).lower().replace("−","-")
    @staticmethod
    def _concept_id(concept:str)->str:return re.sub(r"[^a-z0-9]+","_",concept.strip().lower()).strip("_")
