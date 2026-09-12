# EduOS — System Architecture & Data Flow

**Version:** 1.0

---

## 1. High-Level Architecture

```text
                 ┌──────────────────────┐
                 │      STUDENTS        │
                 └──────────┬───────────┘
                            │
              ┌─────────────┴─────────────┐
              ↓                           ↓
       Flutter Mobile                Next.js Web
       Daily Learning                Tests / Teacher
              │                           │
              └─────────────┬─────────────┘
                            ↓
                     FastAPI Backend
                            │
       ┌────────────────────┼────────────────────┐
       ↓                    ↓                    ↓
 Business Services      AI Services          Analytics
       │                    │                    │
       └────────────────────┼────────────────────┘
                            ↓
                  Supabase PostgreSQL
                            │
                         pgvector
```

---

## 2. Architectural Principles

- API-first.
- Backend as source of truth.
- Database as persistent source of truth.
- AI as a controlled service.
- No direct frontend-to-LLM connection.
- Least privilege.
- Modular code.
- Observable workflows.
- Graceful dependency failure.

---

## 3. Client Layer

### Flutter

Responsibilities:
- mobile student UI;
- local UI state;
- camera/voice input;
- API consumption;
- secure session handling.

### Next.js

Responsibilities:
- desktop student assessment;
- teacher dashboard;
- detailed analytics;
- web student experience.

---

## 4. API Layer

FastAPI handles:
- auth verification;
- routing;
- validation;
- authorization;
- rate limiting;
- service invocation;
- response formatting.

---

## 5. Business Service Layer

Services:

```text
AssessmentService
MasteryService
MindTraceService
PathAIService
TutorService
AnalyticsService
DocumentService
RAGService
```

Each service should own a clear responsibility.

---

## 6. AI Layer

```text
AI Orchestrator
     │
     ├── Tutor
     ├── MindTrace
     ├── PathAI
     └── Content/RAG
```

LangGraph may orchestrate multi-step workflows.

Do not use an agent framework for simple CRUD operations.

---

## 7. Complete Student Data Flow

### Step 1 — Assessment

```text
Student
 ↓
Web
 ↓
POST /assessments/start
 ↓
FastAPI
 ↓
Supabase
```

### Step 2 — Answer

```text
Student Answer
 ↓
FastAPI
 ↓
Validate
 ↓
Save assessment_answers
```

### Step 3 — Submit

```text
Submit
 ↓
AssessmentService
 ↓
Evaluate
 ↓
Save result
```

### Step 4 — Diagnosis

```text
Incorrect answer
 ↓
MindTraceService
 ↓
Context Builder
 ↓
RAG/history
 ↓
LLM
 ↓
Structured diagnosis
 ↓
Validation
 ↓
Save misconception
```

### Step 5 — EduTwin

```text
Assessment + practice evidence
 ↓
MasteryService
 ↓
new mastery
 ↓
student_mastery
 ↓
mastery_history
```

### Step 6 — PathAI

```text
Learning Twin
+
Misconception
+
Prerequisites
 ↓
PathAI
 ↓
Recommendation
```

### Step 7 — Intervention

```text
Student
 ↓
Explanation
 ↓
Practice
 ↓
Reassessment
```

### Step 8 — Update

```text
Reassessment
 ↓
MasteryService
 ↓
EduTwin update
```

---

## 8. Teacher Data Flow

```text
Student Events
 ↓
Assessment Data
 ↓
Mastery Data
 ↓
Misconceptions
 ↓
Aggregation
 ↓
ClassPulse
 ↓
Teacher Dashboard
```

Example:

```text
42 students
      ↓
Concept aggregation
      ↓
14 weak in Factorization
      ↓
Common pattern detected
      ↓
AI recommendation
```

---

## 9. Cross-Device Synchronization

There is no direct mobile-to-desktop sync.

Both clients use the backend.

```text
Flutter
   ↓
FastAPI
   ↓
Supabase
   ↑
FastAPI
   ↑
Next.js
```

This ensures:
- one source of truth;
- consistent state;
- centralized permissions.

---

## 10. File/RAG Flow

```text
Teacher uploads PDF
       ↓
Backend validates
       ↓
Storage
       ↓
Text extraction
       ↓
Chunking
       ↓
Embedding
       ↓
pgvector
       ↓
RAG retrieval
```

---

## 11. Camera Flow

Optional MVP capability:

```text
Camera
 ↓
Image validation
 ↓
OCR
 ↓
Extracted text
 ↓
Question/answer analysis
```

If OCR quality is low:
- ask student to confirm;
- do not silently invent text.

---

## 12. Voice Flow

Optional:

```text
Microphone
 ↓
Speech-to-text
 ↓
Text validation
 ↓
Tutor / analysis
 ↓
Response
```

Do not make voice mandatory for the core assessment loop.

---

## 13. Knowledge Graph

MVP can represent concept relationships in PostgreSQL:

```text
Concept
 ├── parent
 └── prerequisites
```

Example:

```text
Algebra
 ↓
Factorization
 ↓
Quadratic Equations
```

A graph database is optional in future versions.

---

## 14. Security Boundaries

```text
Client
  │
  │ HTTPS
  ↓
API Gateway/Application
  │
  ├── Auth
  ├── Authorization
  ├── Validation
  ↓
Services
  ↓
Database
```

LLM credentials exist only server-side.

---

## 15. Failure Architecture

### Database unavailable

Show:
> Service temporarily unavailable. Please try again.

### AI unavailable

Preserve:
- assessment;
- score;
- progress.

Allow AI analysis retry.

### RAG unavailable

Tutor may provide a clearly labeled general response if policy permits, or ask the user to retry.

---

## 16. Deployment Architecture

```text
GitHub
  ↓
CI/CD
  ├── Next.js → Vercel
  ├── FastAPI → Cloud runtime
  └── Database → Supabase
```

Flutter:
- build Android APK;
- distribute for demo/testing.

---

## 17. Future Scale

Potential future components:
- queue;
- worker service;
- Redis;
- dedicated vector database;
- model gateway;
- analytics warehouse.

These are not required for MVP.

---

## 18. Architecture Definition of Done

- all clients use versioned APIs;
- no direct client-to-LLM calls;
- data ownership is enforced;
- AI results are validated;
- cross-device state is consistent;
- critical failures are recoverable;
- production deployment is reproducible.
