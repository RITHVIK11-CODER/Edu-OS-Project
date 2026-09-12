# EduOS — Database Schema & Data Model

**Version:** 1.0  
**Database:** PostgreSQL via Supabase  
**Vector:** pgvector  
**Primary key:** UUID unless noted  
**Timestamps:** UTC

---

## 1. Data Model Principles

1. Relational source of truth.
2. Stable UUID identifiers.
3. Foreign keys for relationships.
4. Explicit role and ownership checks.
5. Audit fields where useful.
6. Do not store secrets in application tables.
7. AI output must be structured before persistence.
8. Keep assessment facts separate from derived analytics.
9. Store enough history to explain how mastery changed.

---

## 2. Core Entity Graph

```text
users
 ├── students
 │     ├── enrollments
 │     ├── assessment_attempts
 │     ├── student_mastery
 │     ├── student_mistakes
 │     └── learning_events
 │
 └── teachers
       └── class_memberships

subjects
 └── concepts
       └── concept_prerequisites

assessments
 └── assessment_questions
       └── questions

assessment_attempts
 └── assessment_answers
       └── mindtrace_analyses

documents
 └── document_chunks
       └── embeddings

recommendations
```

---

## 3. users

Purpose: application identity/profile linkage.

Fields:
- `id uuid primary key`
- `auth_user_id uuid unique not null`
- `role enum not null`
- `display_name text`
- `created_at timestamptz`
- `updated_at timestamptz`

Roles:
- STUDENT
- TEACHER
- ADMIN

Do not store passwords.

---

## 4. students

Fields:
- `id uuid primary key`
- `user_id uuid unique references users(id)`
- `grade int`
- `section text`
- `school_id uuid nullable`
- `created_at`
- `updated_at`

Validation:
- grade must be within supported product range;
- MVP UI should expose Grade 10.

---

## 5. teachers

Fields:
- `id uuid primary key`
- `user_id uuid unique references users(id)`
- `school_id uuid nullable`
- `created_at`
- `updated_at`

---

## 6. schools

Fields:
- `id uuid primary key`
- `name text not null`
- `created_at`
- `updated_at`

MVP can use a demo school or nullable school association.

---

## 7. classes

Fields:
- `id uuid primary key`
- `school_id uuid nullable`
- `name text`
- `grade int`
- `section text`
- `academic_year text`
- `created_at`

---

## 8. class_memberships

Fields:
- `id uuid primary key`
- `class_id uuid references classes`
- `student_id uuid references students`
- `joined_at`

Unique:
- `(class_id, student_id)`

---

## 9. teacher_class_memberships

Fields:
- `id uuid primary key`
- `class_id uuid references classes`
- `teacher_id uuid references teachers`
- `role text`
- `created_at`

---

## 10. subjects

Fields:
- `id uuid primary key`
- `name text`
- `code text unique`
- `grade int nullable`
- `description text`
- `created_at`

Example:
- Mathematics.

---

## 11. concepts

Fields:
- `id uuid primary key`
- `subject_id uuid references subjects`
- `parent_concept_id uuid nullable references concepts`
- `name text`
- `description text`
- `difficulty int`
- `created_at`

Examples:
- Algebra
- Factorization
- Quadratic Equations.

---

## 12. concept_prerequisites

Fields:
- `concept_id uuid references concepts`
- `prerequisite_concept_id uuid references concepts`
- `weight numeric`
- primary key `(concept_id, prerequisite_concept_id)`

Example:

```text
Quadratic Equations
    ↓ prerequisite
Factorization
```

Avoid cycles during content creation.

---

## 13. questions

Fields:
- `id uuid primary key`
- `subject_id`
- `concept_id`
- `question_text`
- `question_type`
- `options jsonb nullable`
- `correct_answer jsonb`
- `explanation text`
- `difficulty int`
- `source_type text`
- `created_at`
- `updated_at`

Do not expose `correct_answer` to clients during an active assessment.

---

## 14. assessments

Fields:
- `id uuid primary key`
- `title`
- `subject_id`
- `grade`
- `description`
- `duration_seconds`
- `status`
- `created_at`

---

## 15. assessment_questions

Fields:
- `assessment_id`
- `question_id`
- `sequence int`
- primary key `(assessment_id, question_id)`

---

## 16. assessment_attempts

Fields:
- `id uuid primary key`
- `assessment_id`
- `student_id`
- `status`
- `started_at`
- `submitted_at`
- `completed_at`
- `score numeric nullable`
- `total_questions int`
- `correct_answers int`
- `created_at`

Constraint:
- completed attempt cannot be submitted again.

---

## 17. assessment_answers

Fields:
- `id uuid primary key`
- `attempt_id`
- `question_id`
- `student_answer jsonb`
- `is_correct boolean nullable`
- `time_taken_seconds int nullable`
- `submitted_at`
- `evaluation_status`
- `created_at`

Unique:
- `(attempt_id, question_id)`

---

## 18. student_mastery

This is the core EduTwin state table.

Fields:
- `id uuid primary key`
- `student_id`
- `concept_id`
- `mastery_score numeric`
- `status`
- `evidence_count int`
- `last_assessed_at`
- `updated_at`

Suggested score:
- 0–100.

Status is derived:
- weak;
- developing;
- strong;
- mastered.

---

## 19. mastery_history

Never overwrite history if the product needs explainability.

Fields:
- `id uuid primary key`
- `student_id`
- `concept_id`
- `previous_score`
- `new_score`
- `source_type`
- `source_id`
- `created_at`

This allows:

```text
41 → 55 → 68 → 76
```

to be explained.

---

## 20. student_mistakes

Fields:
- `id uuid primary key`
- `student_id`
- `attempt_id`
- `answer_id`
- `concept_id`
- `mistake_type`
- `created_at`

---

## 21. misconceptions

Fields:
- `id uuid primary key`
- `student_id`
- `concept_id`
- `title`
- `description`
- `root_concept_id`
- `confidence numeric`
- `source_answer_id`
- `status`
- `created_at`
- `updated_at`

Status:
- ACTIVE
- RESOLVED
- REVIEW

---

## 22. recommendations

Fields:
- `id uuid primary key`
- `student_id`
- `concept_id`
- `type`
- `reason`
- `priority`
- `duration_minutes`
- `status`
- `created_at`
- `completed_at`

Types:
- EXPLAIN
- HINT
- PRACTICE
- REVISE
- REASSESS

---

## 23. learning_events

Event-oriented history.

Fields:
- `id uuid primary key`
- `student_id`
- `event_type`
- `entity_type`
- `entity_id`
- `metadata jsonb`
- `created_at`

Examples:
- ASSESSMENT_STARTED
- QUESTION_ANSWERED
- MISCONCEPTION_DETECTED
- PRACTICE_COMPLETED
- REASSESSMENT_COMPLETED

Do not put sensitive content in metadata unnecessarily.

---

## 24. documents

Fields:
- `id uuid primary key`
- `uploaded_by`
- `title`
- `file_path`
- `mime_type`
- `grade`
- `subject_id`
- `status`
- `created_at`

---

## 25. document_chunks

Fields:
- `id uuid primary key`
- `document_id`
- `chunk_index`
- `content`
- `metadata jsonb`
- `embedding vector(...)`
- `created_at`

Embedding dimension must match the selected embedding model.

---

## 26. AI analysis records

Recommended table:

`ai_analysis_runs`

Fields:
- `id`
- `student_id`
- `analysis_type`
- `source_id`
- `provider`
- `model`
- `input_hash`
- `output jsonb`
- `confidence numeric`
- `status`
- `latency_ms`
- `created_at`

Do not store secrets.

---

## 27. Indexes

Recommended:
- students.user_id;
- class_memberships.class_id;
- class_memberships.student_id;
- concepts.subject_id;
- questions.concept_id;
- assessment_questions.assessment_id;
- assessment_attempts.student_id;
- assessment_answers.attempt_id;
- student_mastery.student_id;
- student_mastery.concept_id;
- misconceptions.student_id;
- recommendations.student_id;
- learning_events.student_id.

For pgvector, create the appropriate vector index only after confirming embedding dimensions and workload.

---

## 28. Row-Level Security

Supabase RLS should restrict:
- students to their own data;
- teachers to assigned classes;
- admins to authorized administrative data.

However, sensitive business operations should still be performed through a properly authorized backend.

---

## 29. Data Lifecycle

For MVP:
- keep assessment history;
- keep mastery history;
- keep AI analysis records needed for debugging/evaluation;
- avoid storing unnecessary raw personal data.

Future production should define:
- retention;
- deletion;
- export;
- archival.

---

## 30. Database Definition of Done

- all FK relationships work;
- unique constraints prevent duplicate submissions;
- RLS is tested;
- seed data exists;
- migrations are version controlled;
- indexes exist for main queries;
- sensitive fields are not accidentally exposed;
- test reset/seed scripts work.

---

## 31. Demo Seed Data

Create:
- one demo teacher;
- one Grade 10 class;
- one demo student;
- Mathematics subject;
- 5–10 concepts;
- 20–30 questions;
- 2–5 assessments;
- representative mastery/mistake data.

This makes the hackathon demo repeatable.
