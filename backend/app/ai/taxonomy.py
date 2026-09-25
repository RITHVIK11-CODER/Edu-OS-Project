"""Controlled misconception taxonomy for the Grade 10 Mathematics MVP."""
from dataclasses import dataclass
@dataclass(frozen=True)
class MisconceptionDefinition:
    code:str
    label:str
    root_cause:str
MISCONCEPTIONS={
"incorrect_factor_pair":MisconceptionDefinition("incorrect_factor_pair","Incorrect factor pair","The selected factors do not satisfy the required product and/or middle-term relationship."),
"coefficient_misinterpretation":MisconceptionDefinition("coefficient_misinterpretation","Coefficient misinterpretation","The student appears to misread or incorrectly apply a coefficient in the expression."),
"arithmetic_error":MisconceptionDefinition("arithmetic_error","Arithmetic error","The method is plausible, but a numerical calculation appears to be incorrect."),
"sign_error":MisconceptionDefinition("sign_error","Sign error","A positive/negative sign was handled incorrectly during the solution."),
"incomplete_factorization":MisconceptionDefinition("incomplete_factorization","Incomplete factorization","The response starts the factorization process but does not complete the required factorization."),
"formula_misapplication":MisconceptionDefinition("formula_misapplication","Formula misapplication","A quadratic formula or identity is applied to the wrong structure or with incorrect substitution."),
"conceptual_gap":MisconceptionDefinition("conceptual_gap","Conceptual gap","The response does not show the prerequisite understanding needed for the tested concept."),
"procedural_error":MisconceptionDefinition("procedural_error","Procedural error","The student appears to know the concept but misses or reorders an important solution step."),
"unknown":MisconceptionDefinition("unknown","Unclear misconception","The available response does not provide enough evidence for a more specific diagnosis.")}
def get_definition(code:str)->MisconceptionDefinition:return MISCONCEPTIONS.get(code,MISCONCEPTIONS["unknown"])
