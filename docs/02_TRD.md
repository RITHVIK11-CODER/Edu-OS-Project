# EduOS — Technical Requirements Document (TRD)

**Version:** 1.0  
**Architecture:** Modular monolith + AI service layer  
**Frontend:** Flutter + Next.js  
**Backend:** FastAPI  
**Database:** Supabase PostgreSQL  
**Vector Search:** pgvector  
**AI:** Provider abstraction supporting Gemini/OpenAI  
**Orchestration:** LangGraph where multi-step orchestration adds value

---

## 1. Technical Objective

Build a maintainable, secure, testable cross-platform application that can deliver the EduOS MVP within a constrained hackathon timeline while preserving a clean path to production scale.

The implementation must prioritize:
1. correctness;
2. simplicity;
3. observability;
4. secure data handling;
5. deterministic business logic;
6. structured AI outputs;
7. easy deployment.

---

## 2. Architecture Decision

### Recommended MVP architecture

```text
Flutter Mobile ───────┐
                      │
Next.js Web ──────────┤
                      ↓
                 FastAPI API
                      │
       ┌──────────────┼──────────────┐
       ↓              ↓              ↓
 Business Logic    AI Services     Analytics
       │              │              │
       └──────────────┼──────────────┘
                      ↓
               Supabase PostgreSQL
                      │
                   pgvector
```

Do not introduce microservices unless a real scaling requirement exists.

---

## 3. Technology Stack

### Frontend mobile
Flutter / Dart.

Responsibilities:
- student experience;
- mobile learning;
- AI tutor;
- practice;
- progress;
- camera/voice integration when included.

### Web
Next.js / React / TypeScript.

Responsibilities:
- student assessments;
- detailed results;
- teacher dashboard;
- responsive web experience.

### Backend
Python + FastAPI.

Responsibilities:
- authentication verification;
- authorization;
- API contracts;
- business logic;
- database access;
- AI orchestration;
- validation;
- analytics.

### Database
Supabase PostgreSQL.

Responsibilities:
- relational data;
- authentication integration;
- storage;
- row-level access policies where appropriate.

### Vector search
PostgreSQL pgvector.

Use it for:
- document embeddings;
- semantic retrieval;
- curriculum content retrieval.

### AI
Use a provider abstraction.

Supported providers:
- Gemini;
- OpenAI.

The application must not scatter provider-specific SDK calls throughout business logic.

---

## 4. Environment Model

Minimum environments:

```text
local
staging/demo
production
```

For the hackathon, local + production may be enough.

Required environment variables should be documented in `.env.example`.

Examples:

```text
DATABASE_URL
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
LLM_PROVIDER
GEMINI_API_KEY
OPENAI_API_KEY
CORS_ORIGINS
APP_ENV
```

Never commit actual secret values.

---

## 5. Repository Structure

```text
EduOS/
├── mobile/
├── web/
├── backend/
├── database/
├── ai/
├── docs/
├── scripts/
├── .env.example
├── README.md
└── .gitignore
```

Backend:

```text
backend/
├── app/
│   ├── main.py
│   ├── api/
│   │   └── v1/
│   ├── core/
│   ├── database/
│   ├── models/
│   ├── schemas/
│   ├── services/
│   ├── ai/
│   └── utils/
├── tests/
├── requirements.txt
└── Dockerfile
```

---

## 6. API Design

Use versioned REST APIs:

```text
/api/v1/...
```

Resources:
- auth;
- students;
- subjects;
- concepts;
- assessments;
- attempts;
- MindTrace;
- EduTwin;
- PathAI;
- tutor;
- documents;
- teacher analytics.

Use JSON.

Use consistent success/error envelopes.

---

## 7. Data Rules

The backend owns business-critical state.

Frontend must not directly decide:
- mastery;
- misconception;
- teacher authorization;
- assessment completion;
- recommendation validity.

Frontend may calculate purely presentational state such as:
- local countdown display;
- UI animations;
- temporary form state.

---

## 8. Assessment State Machine

Assessment attempt states:

```text
CREATED
  ↓
IN_PROGRESS
  ↓
SUBMITTED
  ↓
EVALUATED
  ↓
COMPLETED
```

Optional failure state:

```text
PROCESSING_ERROR
```

Once completed, an attempt must not be submitted again.

---

## 9. Learning State

Concept mastery should be stored as a numeric score plus a derived status.

Recommended range:

```text
0–100
```

Suggested display:
- 0–49: weak;
- 50–74: developing;
- 75–89: strong;
- 90–100: mastered.

These are product display thresholds, not scientific claims.

---

## 10. AI Output Requirements

AI output must be structured.

Example:

```json
{
  "is_correct": false,
  "concept_id": "factorization",
  "misconception_title": "Incorrect factor selection",
  "root_concept_id": "factorization",
  "explanation": "The selected factors do not produce the required middle term.",
  "confidence": 0.87,
  "recommended_action": "targeted_practice"
}
```

The backend must validate the schema before persistence.

---

## 11. AI Provider Abstraction

Create:

```python
class LLMProvider:
    async def generate(self, messages, response_schema=None):
        raise NotImplementedError
```

Implement:
- `GeminiProvider`
- `OpenAIProvider`

Services should depend on `LLMProvider`, not on a provider SDK directly.

---

## 12. RAG Requirements

Pipeline:

```text
Upload
 ↓
Validate
 ↓
Extract
 ↓
Chunk
 ↓
Embed
 ↓
Store
 ↓
Retrieve
 ↓
Ground AI response
```

Metadata should include:
- grade;
- subject;
- concept;
- source;
- document ID;
- chunk ID.

Retrieval must respect authorization and content scope.

---

## 13. Performance

Target MVP:
- ordinary API: under 500 ms where feasible;
- DB operations: under 300 ms where feasible;
- non-AI assessment submit: under 2 seconds;
- AI analysis: under 10 seconds target;
- dashboard load: under 2 seconds target.

These are engineering targets, not guaranteed SLAs.

---

## 14. Reliability

Critical rule:

> An AI failure must not erase or invalidate a saved assessment.

Recommended sequence:

```text
Save assessment
 ↓
Mark submission
 ↓
Evaluate deterministic fields
 ↓
Queue/execute AI analysis
 ↓
Store AI result
```

If AI fails:
- preserve score;
- mark diagnosis as pending/failed;
- allow retry.

---

## 15. Observability

Log:
- request ID;
- endpoint;
- status;
- latency;
- non-sensitive error details;
- AI provider;
- AI duration.

Do not log:
- passwords;
- tokens;
- API keys;
- unnecessary full student responses;
- sensitive student information.

---

## 16. Scalability

MVP should use a modular monolith.

Future extraction candidates:
- AI inference;
- document processing;
- analytics;
- notification service.

Do not prematurely split services.

---

## 17. Coding Standards

### Python
- type hints;
- Pydantic schemas;
- async I/O where appropriate;
- service layer;
- clear exceptions.

### TypeScript
- strict mode;
- typed API responses;
- reusable components;
- no `any` unless justified.

### Flutter
- feature-based folders;
- typed models;
- repository/service separation;
- predictable state management.

---

## 18. Technical Definition of Done

A feature is done when:
- implementation exists;
- API contract is documented;
- validation exists;
- error state exists;
- authorization exists;
- test exists;
- frontend integration works;
- production build succeeds.

---

## 19. Explicit Technical Constraints

Do not add:
- Redis unless caching is demonstrated as necessary;
- Pinecone when pgvector is sufficient;
- Neo4j for the MVP;
- Kubernetes;
- three cloud providers;
- multiple agent frameworks;
- direct client-to-LLM calls;
- secrets in frontend code.

---

## 20. Technical Priority

Priority order:

```text
Core learning loop
>
Data correctness
>
AI reliability
>
Security
>
UX polish
>
Optional integrations
```

A smaller correct system is preferable to a larger unstable system.
