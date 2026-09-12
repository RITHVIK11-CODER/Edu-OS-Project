# EduOS — API Documentation

**Version:** 1.0  
**Base Path:** `/api/v1`  
**Format:** JSON  
**Auth:** Bearer token  
**Backend:** FastAPI

---

## 1. API Conventions

### Success

```json
{
  "success": true,
  "data": {},
  "message": "Success"
}
```

### List

```json
{
  "success": true,
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 20
  }
}
```

### Error

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request",
    "details": {}
  }
}
```

---

## 2. Authentication

### POST `/auth/register`

Creates an account through Supabase Auth.

Request:

```json
{
  "email": "student@example.com",
  "password": "strong-password",
  "display_name": "Arjun",
  "role": "STUDENT"
}
```

Validation:
- email format;
- password policy;
- allowed role.

The backend must not accept arbitrary privileged roles from untrusted clients. In production, teacher/admin creation should require an authorized workflow.

### POST `/auth/login`

Request:

```json
{
  "email": "student@example.com",
  "password": "strong-password"
}
```

Response includes session/access information according to the chosen Supabase Auth integration.

### GET `/auth/me`

Returns:
- user ID;
- role;
- display name.

---

## 3. Student APIs

### GET `/students/me`

Returns student profile.

### GET `/students/me/progress`

Returns summary:
- overall mastery;
- recent assessments;
- recommended action.

### GET `/students/me/learning-twin`

Returns concept mastery.

---

## 4. Subject APIs

### GET `/subjects`

Returns accessible subjects.

### GET `/subjects/{subject_id}/concepts`

Returns concepts for the subject.

Query options:
- grade;
- parent concept.

---

## 5. Assessment APIs

### GET `/assessments`

Returns available assessments.

### GET `/assessments/{assessment_id}`

Returns metadata without exposing answer keys.

### POST `/assessments/{assessment_id}/start`

Creates attempt.

Response:

```json
{
  "success": true,
  "data": {
    "attempt_id": "uuid",
    "status": "IN_PROGRESS",
    "started_at": "2026-09-12T10:00:00Z"
  }
}
```

### GET `/assessments/{assessment_id}/questions`

Returns safe question representation.

Never return correct answers.

### POST `/attempts/{attempt_id}/answers`

Request:

```json
{
  "question_id": "uuid",
  "student_answer": "x = 2,3",
  "time_taken_seconds": 42
}
```

The backend validates:
- attempt ownership;
- question belongs to assessment;
- attempt is active.

### POST `/attempts/{attempt_id}/submit`

Completes attempt.

Backend:
1. validates state;
2. locks submission;
3. evaluates answers;
4. calculates score;
5. stores results;
6. identifies candidate misconceptions;
7. updates EduTwin;
8. triggers AI diagnosis when configured.

---

## 6. Results

### GET `/attempts/{attempt_id}/result`

Returns:
- score;
- counts;
- concept performance;
- mistakes;
- recommendations.

Correct answers may be exposed after submission according to product policy.

---

## 7. MindTrace

### POST `/mindtrace/analyze`

Request:

```json
{
  "student_id": "uuid",
  "attempt_id": "uuid",
  "answer_id": "uuid"
}
```

The backend should load the actual question, answer, concept, and authorized student context instead of trusting the client to provide all facts.

Response:

```json
{
  "success": true,
  "data": {
    "analysis_id": "uuid",
    "concept_id": "uuid",
    "misconception": {
      "title": "Incorrect factor selection",
      "description": "The response suggests the student selected factors that do not produce the required middle term.",
      "root_concept_id": "uuid",
      "confidence": 0.87
    },
    "recommended_action": "PRACTICE"
  }
}
```

---

## 8. EduTwin

### GET `/learning-twin/me`

Returns:
- overall mastery;
- subject mastery;
- concept mastery;
- status;
- recent changes.

### GET `/learning-twin/me/concepts/{concept_id}`

Returns:
- current mastery;
- history;
- recent evidence;
- active misconceptions.

### POST `/learning-twin/recalculate`

Internal/admin/debug endpoint only. Do not expose broadly.

---

## 9. PathAI

### POST `/pathai/recommend`

Request:

```json
{
  "concept_id": "uuid"
}
```

The backend derives:
- student;
- mastery;
- mistakes;
- misconceptions;
- prerequisites;
- recent learning.

Response:

```json
{
  "success": true,
  "data": {
    "recommendation_id": "uuid",
    "concept_id": "uuid",
    "action": "PRACTICE",
    "reason": "Repeated factor-selection misconception detected.",
    "duration_minutes": 5,
    "steps": [
      "EXPLAIN",
      "PRACTICE",
      "REASSESS"
    ]
  }
}
```

---

## 10. Practice APIs

### GET `/practice/recommended`

Returns recommended practice.

### POST `/practice/{activity_id}/submit`

Stores practice result.

Practice results should update learning state only through defined backend logic.

---

## 11. Reassessment APIs

### POST `/reassessments`

Creates a targeted reassessment based on a concept.

### POST `/reassessments/{id}/submit`

Evaluates and updates EduTwin.

---

## 12. AI Tutor

### POST `/tutor/chat`

Request:

```json
{
  "message": "Explain factorization.",
  "concept_id": "uuid",
  "conversation_id": "uuid"
}
```

Backend context:
- grade;
- subject;
- concept;
- learning twin;
- recent relevant mistakes;
- RAG results.

Response:

```json
{
  "success": true,
  "data": {
    "message": "Let's understand factorization step by step...",
    "suggested_action": "PRACTICE"
  }
}
```

The server must enforce:
- input length;
- rate limits;
- role;
- content policy.

---

## 13. Documents

### POST `/documents/upload`

Accept only approved MIME types.

### GET `/documents`

Returns documents accessible to the user.

### POST `/documents/{id}/process`

Internal/authorized processing endpoint.

---

## 14. RAG

### POST `/rag/search`

Request:

```json
{
  "query": "Explain factorization",
  "subject_id": "uuid",
  "grade": 10,
  "top_k": 5
}
```

Response includes:
- source;
- chunk;
- similarity;
- metadata.

Do not expose private documents outside their permitted scope.

---

## 15. Teacher APIs

### GET `/teacher/classes`

### GET `/teacher/classes/{class_id}/analytics`

### GET `/teacher/classes/{class_id}/concepts`

### GET `/teacher/classes/{class_id}/students`

### GET `/teacher/classes/{class_id}/attention`

### GET `/teacher/classes/{class_id}/misconceptions`

### POST `/teacher/classes/{class_id}/recommendation`

Teacher endpoints must verify assignment to the class.

---

## 16. Analytics Response

Example:

```json
{
  "students": 42,
  "average_mastery": 71,
  "weak_concepts": [
    {
      "concept_id": "uuid",
      "name": "Factorization",
      "mastery": 43,
      "affected_students": 14
    }
  ],
  "attention_count": 6
}
```

---

## 17. HTTP Status Policy

- 200 successful;
- 201 created;
- 204 no content;
- 400 malformed;
- 401 unauthenticated;
- 403 unauthorized;
- 404 missing;
- 409 conflict;
- 422 validation;
- 429 rate limited;
- 500 internal;
- 503 dependency unavailable.

---

## 18. Pagination

Use:
- `page`;
- `limit`.

Maximum limit should be enforced.

For high-scale future APIs, cursor pagination can replace page pagination.

---

## 19. Idempotency

Critical operations must be idempotent where duplicate requests are possible.

Especially:
- assessment submission;
- answer submission;
- reassessment submission.

Use attempt state + unique constraints and, where necessary, idempotency keys.

---

## 20. API Security

Every protected endpoint:
1. validates token;
2. identifies user;
3. checks role;
4. checks resource ownership;
5. executes action.

Never trust:
- `student_id` from frontend;
- `teacher_id` from frontend;
- role values from frontend;
- concept mastery supplied by frontend.

---

## 21. API Testing

Every endpoint should have:
- happy path;
- missing auth;
- wrong role;
- invalid ID;
- invalid body;
- duplicate request;
- dependency failure where relevant.

---

## 22. API Versioning

Do not remove or change a public contract casually.

Breaking changes require:
- version change;
- migration;
- frontend update.

---

## 23. API Documentation Rule for Vibe Coding

Before implementing an endpoint, the AI coding agent must:
1. search the existing API implementation;
2. check this document;
3. reuse existing schemas/services;
4. avoid duplicate endpoints;
5. add tests;
6. update documentation if behavior changes.
