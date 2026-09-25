"""Explainable next-action selection for the Grade 10 Mathematics MVP."""
from ..models import LearningAction,PathAIInput,PathAIRecommendation
class PathAIEngine:
    def recommend(self,data:PathAIInput)->PathAIRecommendation:
        weak=next((name for name,mastery in data.prerequisite_mastery.items() if mastery<.50),None)
        if weak and data.mastery<.55:return PathAIRecommendation(action=LearningAction.PREREQUISITE_REVIEW,concept=data.concept,reason=f"Prerequisite concept '{weak}' is below 50% mastery.",difficulty="easy",question_count=2,steps=["REVIEW_PREREQUISITE","WORKED_EXAMPLE","REASSESS"])
        if data.mastery<.45 and data.active_misconception:return PathAIRecommendation(action=LearningAction.TARGETED_PRACTICE,concept=data.concept,reason=f"Low mastery with active misconception '{data.active_misconception}' indicates targeted practice is needed.",difficulty="easy",question_count=3,steps=["EXPLAIN","WORKED_EXAMPLE","PRACTICE","REASSESS"])
        if data.active_misconception and data.confidence>=.65:return PathAIRecommendation(action=LearningAction.WORKED_EXAMPLE,concept=data.concept,reason=f"A supported misconception '{data.active_misconception}' needs a worked example before more practice.",difficulty="easy",question_count=2,steps=["EXPLAIN","WORKED_EXAMPLE","PRACTICE"])
        if data.mastery<.70:return PathAIRecommendation(action=LearningAction.REVIEW_CONCEPT,concept=data.concept,reason="Mastery is still developing and additional concept review is appropriate.",difficulty="medium",question_count=3,steps=["REVIEW","PRACTICE","REASSESS"])
        if data.mastery<.85:return PathAIRecommendation(action=LearningAction.REASSESSMENT,concept=data.concept,reason="The student has developing mastery and can verify improvement with a focused reassessment.",difficulty="medium",question_count=3,steps=["REASSESS"])
        return PathAIRecommendation(action=LearningAction.ADVANCE_TO_NEXT_CONCEPT,concept=data.concept,reason="Mastery is high and no active misconception requires intervention.",difficulty="hard",question_count=0,steps=["ADVANCE"])
