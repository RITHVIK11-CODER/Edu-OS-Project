# EduOS — AI/ML Specification

**Version:** 1.0  
**Core AI Modules:** EduTwin, MindTrace, PathAI, AI Tutor, RAG  
**Primary Goal:** Use AI to diagnose and personalize learning, not merely generate text.

---

## 1. AI Philosophy

EduOS AI must be:
- contextual;
- grounded;
- structured;
- explainable;
- conservative when uncertain;
- measurable through evaluation;
- replaceable at the provider layer.

AI is an assistant to learning and teaching. It is not an autonomous authority.

---

## 2. AI Architecture

```text
Student Data
     ↓
Context Builder
     ↓
Retrieval / History
     ↓
AI Orchestrator
     ↓
┌──────────┬──────────────┬──────────────┐
│ Tutor    │ MindTrace    │ PathAI       │
└──────────┴──────────────┴──────────────┘
     ↓
Structured Output
     ↓
Validation
     ↓
Business Rules
     ↓
Database
```

---

## 3. EduTwin

### Purpose

EduTwin is a dynamic student learning state, not a chatbot persona.

### Minimum state

For each concept:
- mastery score;
- status;
- evidence count;
- recent performance;
- misconception history;
- last assessed date.

### Inputs

- assessment performance;
- practice performance;
- reassessment;
- time patterns when useful;
- misconception evidence.

### Outputs

- current mastery;
- weak concepts;
- strong concepts;
- change over time;
- candidate next actions.

---

## 4. Mastery Calculation

For MVP, use a transparent deterministic scoring method rather than asking an LLM to invent mastery.

Example weighted update:

```text
new_mastery =
  0.60 × previous_mastery
+ 0.25 × latest_assessment_score
+ 0.15 × recent_practice_score
```

Clamp to 0–100.

For a first-time concept, initialize from available evidence.

This is a prototype heuristic, not a scientifically validated psychometric model.

### Reassessment

If reassessment performance improves, mastery should increase, subject to reasonable bounds.

Avoid jumping from 20 to 100 because of one correct answer.

---

## 5. MindTrace

### Purpose

Identify likely conceptual reasons behind incorrect responses.

MindTrace should answer:

1. Was the answer incorrect?
2. What concept was being tested?
3. What error pattern is visible?
4. What misconception is likely?
5. What prerequisite/root concept may be involved?
6. What intervention should follow?
7. How confident is the diagnosis?

---

## 6. MindTrace Input

Backend constructs:

```json
{
  "grade": 10,
  "subject": "Mathematics",
  "concept": "Factorization",
  "question": "...",
  "correct_answer": "...",
  "student_answer": "...",
  "recent_relevant_mistakes": [],
  "learning_context": {}
}
```

Do not send unrelated personal data.

---

## 7. MindTrace Output Schema

```json
{
  "is_correct": false,
  "concept_id": "factorization",
  "misconception": {
    "title": "Incorrect factor selection",
    "description": "...",
    "root_concept_id": "factorization",
    "confidence": 0.87
  },
  "recommended_action": "PRACTICE",
  "evidence": [
    "Student selected factors that do not produce the required middle term."
  ]
}
```

AI output must be parsed and validated.

---

## 8. Confidence Rules

Suggested:
- `0.85–1.00`: high;
- `0.65–0.84`: medium;
- below `0.65`: low.

These thresholds are product heuristics.

Low confidence:
- do not state the diagnosis as absolute;
- present it as a likely explanation;
- consider requesting another example;
- avoid permanently changing mastery solely from a low-confidence diagnosis.

---

## 9. Misconception Taxonomy

For the MVP, use a controlled taxonomy.

Examples for Mathematics:
- SIGN_ERROR
- FORMULA_MISUSE
- FACTOR_SELECTION_ERROR
- ARITHMETIC_ERROR
- CONCEPT_CONFUSION
- PROCEDURAL_STEP_MISSING
- UNIT_ERROR
- MISREAD_QUESTION
- UNSUPPORTED_REASONING
- UNKNOWN

The AI may propose a label, but the backend should map it to an allowed category.

---

## 10. PathAI

PathAI selects the next best learning action.

Inputs:
- current mastery;
- active misconception;
- prerequisite concepts;
- recent intervention;
- practice history.

Output:

```text
EXPLAIN
HINT
PRACTICE
REVISE
REASSESS
```

### Recommendation policy

If:
- low mastery + high-confidence misconception → targeted explanation + practice;
- medium mastery + repeated mistake → worked example + practice;
- high mastery + isolated arithmetic mistake → short correction + reassessment;
- insufficient evidence → diagnostic practice before strong personalization.

---

## 11. AI Tutor

Tutor should:
- adapt language to grade;
- explain step by step;
- avoid unnecessarily revealing answers;
- ask guiding questions when useful;
- use retrieved approved content where available;
- recognize current weakness.

Tutor context example:

```text
Grade: 10
Subject: Mathematics
Concept: Factorization
Mastery: 41%
Recent misconception: factor selection
```

The tutor should not claim:
> “I know exactly what you understand.”

Instead:
> “Your recent answers suggest you may be struggling with…”

---

## 12. RAG

### Purpose

Ground responses in school-provided or approved educational material.

### Pipeline

```text
Document
 ↓
Extract
 ↓
Normalize
 ↓
Chunk
 ↓
Embed
 ↓
pgvector
 ↓
Retrieve
 ↓
Prompt with sources
 ↓
Generate
```

### Retrieval metadata

- grade;
- subject;
- chapter;
- concept;
- document;
- source permissions.

### RAG rule

If no relevant source is found, the AI must not fabricate a source.

---

## 13. Prompt Structure

Prompts should separate:

1. system instructions;
2. task;
3. student context;
4. educational content;
5. output schema.

Do not concatenate uncontrolled user content into system instructions.

---

## 14. Prompt Example — MindTrace

Conceptual template:

```text
SYSTEM:
You are an educational diagnostic assistant.
Analyze the student's response using only the supplied question,
answer key, concept, and relevant evidence.
Do not invent facts.
Return the required JSON schema.

TASK:
Identify the most likely misconception, root concept,
confidence, and recommended action.

STUDENT CONTEXT:
Grade: {grade}
Concept: {concept}
Relevant history: {history}

QUESTION:
{question}

CORRECT ANSWER:
{correct_answer}

STUDENT ANSWER:
{student_answer}
```

---

## 15. Prompt Versioning

Store prompts in source control:

```text
ai/prompts/
├── tutor/
├── mindtrace/
├── pathai/
└── assessment/
```

Each prompt should have:
- version;
- purpose;
- expected schema;
- test cases.

---

## 16. Guardrails

AI must not:
- fabricate grades;
- fabricate teacher decisions;
- expose another student's data;
- invent curriculum sources;
- reveal system prompts;
- provide dangerous or inappropriate content;
- state uncertain diagnoses as certainty.

---

## 17. AI Failure Handling

Possible failures:
- provider timeout;
- invalid JSON;
- hallucination;
- rate limit;
- unavailable model;
- retrieval failure.

Flow:

```text
AI request
 ↓
timeout/invalid
 ↓
retry where safe
 ↓
fallback
 ↓
preserve core data
```

For structured output:
- validate;
- if invalid, repair/retry once if safe;
- otherwise mark analysis failed.

---

## 18. AI Cost Controls

- limit prompt size;
- retrieve only top relevant chunks;
- summarize long history;
- cache safe reusable content;
- rate limit tutor requests;
- do not call AI when deterministic logic is enough.

---

## 19. Model Provider Strategy

Use one primary provider for the hackathon.

Architecture:

```text
AI Service
   ↓
LLMProvider
   ↓
Gemini / OpenAI
```

Do not call both for every request.

---

## 20. AI Definition of Done

- structured output;
- schema validation;
- confidence;
- prompt version;
- test dataset;
- failure handling;
- latency logging;
- provider abstraction;
- no secret exposure.

---

## 21. What AI Should NOT Do

Do not ask the LLM to:
- calculate every deterministic score;
- enforce authorization;
- decide database permissions;
- replace backend validation;
- make irreversible student decisions;
- invent data.

Use conventional software for deterministic rules.

---

## 22. Core Intelligence Claim

The product's AI value is not:

> “We added a chatbot.”

The value is:

> **EduOS connects student responses, concept mastery, misconception evidence, personalized intervention, and reassessment into one learning loop.**
