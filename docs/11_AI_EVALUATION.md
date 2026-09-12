# EduOS — AI Evaluation & Validation Plan

**Version:** 1.0  
**Owner:** AI/ML Lead + AI Research Support  
**Purpose:** Prove that EduOS AI produces useful, controlled outputs rather than merely impressive text.

---

## 1. Evaluation Philosophy

AI quality must be measured against predefined expectations.

For MindTrace especially, evaluation should compare:

```text
Expected misconception
vs
AI detected misconception
```

Do not judge the system only by whether its answer sounds intelligent.

---

## 2. Evaluation Components

Evaluate:
1. MindTrace diagnosis.
2. Root concept.
3. Confidence.
4. Recommended action.
5. Tutor correctness.
6. RAG grounding.
7. Structured output validity.
8. AI latency.
9. Failure behavior.

---

## 3. Gold Dataset

Create a curated dataset of at least 20–50 examples for the hackathon.

Fields:

```text
case_id
grade
subject
concept
question
correct_answer
student_answer
expected_correctness
expected_misconception
expected_root_concept
expected_action
notes
```

---

## 4. Dataset Example

```text
Case: M001

Concept:
Factorization

Question:
Factor x² - 5x + 6.

Correct:
(x-2)(x-3)

Student:
(x-2)(x-4)

Expected misconception:
FACTOR_SELECTION_ERROR

Expected root:
Factorization

Expected action:
PRACTICE
```

---

## 5. MindTrace Metrics

### Concept accuracy

```text
correct concept predictions / total cases
```

### Misconception accuracy

```text
correct taxonomy predictions / total cases
```

### Root concept accuracy

Measures whether the system identified the appropriate underlying concept.

### Action relevance

Whether:
- EXPLAIN;
- PRACTICE;
- REVISE;
- REASSESS

matches the expected intervention.

### Structured validity

Percentage of responses conforming to schema without repair.

---

## 6. Suggested Hackathon Thresholds

These are internal prototype targets, not scientific benchmarks:

- 90%+ structured JSON validity;
- 80%+ concept accuracy on curated cases;
- 75%+ misconception accuracy on curated cases;
- 80%+ action relevance.

If the dataset is small, report exact counts instead of presenting them as statistically significant.

---

## 7. Confidence Calibration

Record:

```text
AI confidence
Actual correctness
```

Look for:
- high confidence + wrong diagnosis;
- low confidence + correct diagnosis.

High-confidence errors are more dangerous than low-confidence uncertainty.

---

## 8. Hallucination Evaluation

Test whether AI:
- invents curriculum facts;
- invents source references;
- invents student history;
- invents a misconception not supported by the response.

A good response should distinguish evidence from inference.

---

## 9. RAG Evaluation

For each question:

1. Is the correct source retrieved?
2. Is the answer supported by the source?
3. Does the model cite/identify the source where UI requires it?
4. Does the model avoid fabricating source content?

---

## 10. Tutor Evaluation

Test:
- factual correctness;
- grade appropriateness;
- clarity;
- step-by-step reasoning;
- refusal to invent;
- relevance to student weakness;
- unnecessary answer revelation.

---

## 11. Adversarial Tests

Include:
- “Ignore previous instructions.”
- malicious document text;
- irrelevant text;
- empty answer;
- extremely long answer;
- conflicting context;
- nonsensical question.

Expected:
- system instructions remain protected;
- response stays within educational scope;
- no unauthorized data disclosure.

---

## 12. Regression Set

Every prompt/model change must run against the existing dataset.

Store:
```text
prompt_version
model
case_id
output
pass/fail
reviewer_notes
```

---

## 13. Human Review

For a hackathon:
- AI Research Support reviews every curated case;
- AI Lead reviews failures;
- record ambiguous cases.

For production:
- establish formal evaluation and human review procedures.

---

## 14. Failure Severity

### Critical
- wrong high-confidence diagnosis;
- privacy leakage;
- unsafe content;
- unauthorized data.

### High
- incorrect root concept;
- misleading teacher recommendation.

### Medium
- vague explanation;
- poor practice recommendation.

### Low
- wording;
- formatting.

---

## 15. AI Evaluation Workflow

```text
Dataset
 ↓
Run model
 ↓
Validate schema
 ↓
Compare with expected
 ↓
Calculate metrics
 ↓
Inspect failures
 ↓
Improve prompt/model
 ↓
Re-run
```

---

## 16. Prompt Versioning

Never change production prompts without recording a version.

Example:

```text
mindtrace_v1
mindtrace_v2
```

---

## 17. Model Comparison

If comparing providers:

```text
Same dataset
Same task
Same output schema
Same evaluation criteria
```

Do not cherry-pick the best examples.

---

## 18. AI Evaluation Report

Before demo, record:

```text
Cases tested: 30
Structured validity: 30/30
Concept correct: 26/30
Misconception correct: 24/30
Action relevant: 25/30
High-confidence errors: 1
```

These numbers must come from actual tests.

---

## 19. Go/No-Go Rule

Do not demonstrate a feature as reliable if evaluation reveals repeated critical failures.

Instead:
- narrow the feature;
- lower confidence;
- add human review;
- or remove it from the demo.

---

## 20. Definition of Done

AI feature is demo-ready when:
- evaluation dataset exists;
- schema validation works;
- failure cases are understood;
- critical errors are addressed;
- prompt version is recorded;
- actual metrics are available.
