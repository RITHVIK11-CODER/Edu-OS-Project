# EduOS — Master Engineering Documentation

This directory contains the canonical implementation documentation for EduOS.

## Documents

1. `01_PRD.md` — Product requirements and product behavior.
2. `02_TRD.md` — Technical architecture and engineering requirements.
3. `03_UI_UX.md` — Screen behavior, navigation, UX states, and design rules.
4. `04_DATABASE_SCHEMA.md` — Relational data model and database rules.
5. `05_API_DOCUMENTATION.md` — Endpoint documentation.
6. `06_AI_ML_SPECIFICATION.md` — EduTwin, MindTrace, PathAI, Tutor, RAG.
7. `07_SYSTEM_ARCHITECTURE.md` — End-to-end system and data flows.
8. `08_SECURITY_PRIVACY.md` — Security, privacy, and K–12 safety.
9. `09_TESTING_DEPLOYMENT.md` — QA, testing, release, and deployment.
10. `10_API_CONTRACT.md` — Stable frontend/backend interface contract.
11. `11_AI_EVALUATION.md` — AI evaluation methodology and dataset requirements.
12. `12_MVP_SCOPE.md` — 10-hour hackathon scope and execution plan.

## Source of Truth Priority

If documents appear to conflict, use this priority:

```text
1. Security/privacy constraints
2. API Contract
3. Database/API technical constraints
4. Product requirements
5. UI/UX presentation details
6. Optional/future features
```

If a conflict cannot be resolved safely, do not invent behavior. Ask the project owner.

## Current MVP

```text
Grade 10
→ Mathematics
→ Quadratic Equations
→ Factorization
```

Core loop:

```text
Assess
→ Diagnose
→ Personalize
→ Practice
→ Reassess
→ Update EduTwin
→ Teacher Insight
```

## Vibe Coding Principle

AI coding agents must inspect the existing repository before changing it, follow these documents, reuse existing code, avoid speculative dependencies, preserve API contracts, write tests for meaningful changes, and never implement future scope without explicit approval.
