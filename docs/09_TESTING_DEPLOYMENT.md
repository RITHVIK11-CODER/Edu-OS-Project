# EduOS — Testing, QA & Deployment Specification

**Version:** 1.0

---

## 1. Testing Objective

The objective is not merely to prove that screens load. Testing must prove that the complete learning loop is reliable.

Primary target:

```text
Assessment
 → Evaluation
 → MindTrace
 → EduTwin
 → PathAI
 → Practice
 → Reassessment
 → Updated EduTwin
 → ClassPulse
```

---

## 2. Test Levels

### Unit
Test:
- mastery calculation;
- validation;
- utility functions;
- permission checks;
- recommendation rules.

### Integration
Test:
- API + database;
- API + AI;
- RAG + AI;
- authentication + authorization.

### End-to-end
Test:
- student journey;
- teacher journey;
- cross-device journey.

### AI evaluation
Test:
- diagnosis accuracy;
- structured output;
- confidence;
- recommendation relevance.

---

## 3. Unit Test Priorities

Highest priority:
1. assessment state machine;
2. mastery calculation;
3. authorization;
4. duplicate submission prevention;
5. AI schema validation;
6. recommendation rules.

---

## 4. Assessment Test Cases

### TC-A01
Start valid assessment.

Expected:
- attempt created;
- status IN_PROGRESS.

### TC-A02
Submit valid answer.

Expected:
- answer stored.

### TC-A03
Submit duplicate answer.

Expected:
- no duplicate row;
- defined replacement/rejection behavior.

### TC-A04
Submit completed attempt.

Expected:
- rejected.

### TC-A05
Submit another student's attempt.

Expected:
- 403.

### TC-A06
Submit invalid question ID.

Expected:
- 404/400.

---

## 5. MindTrace Test Cases

Each test case should include:

```text
Question
Correct Answer
Student Answer
Expected Concept
Expected Misconception
Expected Action
```

Example:

```text
Question:
Factor x² - 5x + 6

Student:
(x-2)(x-4)

Expected:
Factor selection error

Expected Action:
PRACTICE
```

---

## 6. EduTwin Tests

Test:
- first assessment;
- repeated correct answers;
- repeated wrong answers;
- reassessment improvement;
- no evidence;
- conflicting evidence.

Example:

Previous mastery = 41  
Assessment = 75  
Practice = 80

Using the documented formula:

```text
0.60(41) + 0.25(75) + 0.15(80)
= 24.6 + 18.75 + 12
= 55.35
```

The implementation must follow the actual chosen formula consistently.

---

## 7. PathAI Tests

### Case 1

Low mastery + high-confidence misconception.

Expected:
- explanation + targeted practice.

### Case 2

Medium mastery + repeated mistake.

Expected:
- worked example + practice.

### Case 3

Insufficient evidence.

Expected:
- diagnostic practice rather than strong diagnosis.

---

## 8. Teacher Analytics Tests

Verify:
- only assigned classes appear;
- aggregate counts are correct;
- weak concepts are ranked correctly;
- student attention list matches rules.

---

## 9. Security Tests

Minimum:
- unauthenticated endpoint;
- wrong role;
- another student's ID;
- another teacher's class;
- expired token;
- invalid input;
- oversized input;
- upload type bypass.

---

## 10. AI Failure Tests

Simulate:
- timeout;
- rate limit;
- malformed JSON;
- empty response;
- provider unavailable.

Expected:
- core data remains safe;
- user receives fallback;
- retry possible.

---

## 11. Frontend QA

For every major screen:
- loading;
- success;
- empty;
- error;
- retry;
- navigation;
- responsive layout;
- accessibility.

---

## 12. Browser/Device QA

Web:
- current Chrome/Edge;
- responsive desktop;
- mobile browser where supported.

Mobile:
- Android target used for hackathon;
- different screen sizes if available.

---

## 13. Performance QA

Measure:
- API latency;
- AI latency;
- page load;
- assessment submit;
- dashboard query.

Do not optimize based on guesses. Measure first.

---

## 14. Deployment

### Web

Next.js → Vercel.

### Backend

FastAPI → selected cloud runtime.

### Database

Supabase.

### Mobile

Flutter → Android APK.

---

## 15. Deployment Checklist

### Backend
- [ ] Production env variables.
- [ ] CORS restricted.
- [ ] HTTPS.
- [ ] Health endpoint.
- [ ] Database connected.
- [ ] migrations applied.
- [ ] logs available.
- [ ] AI provider configured.

### Web
- [ ] production API URL;
- [ ] no localhost references;
- [ ] no secrets in client;
- [ ] build passes.

### Mobile
- [ ] production API URL;
- [ ] app builds;
- [ ] login works;
- [ ] student journey works.

### Database
- [ ] migrations;
- [ ] RLS;
- [ ] seed/demo data;
- [ ] backup strategy where applicable.

---

## 16. Health Endpoint

Implement:

```text
GET /health
```

Response:

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

Do not expose secrets or detailed infrastructure information.

---

## 17. Deployment Strategy

Use:

```text
GitHub
 ↓
Build/Test
 ↓
Deploy
 ↓
Smoke Test
```

For hackathon, manual deployment is acceptable if automated CI is not ready.

---

## 18. Rollback

Maintain:
- known working commit;
- environment configuration;
- database migration awareness.

Do not deploy experimental code immediately before the demo without testing.

---

## 19. Final Smoke Test

Run exactly this before presenting:

```text
1. Login student
2. Open assessment
3. Answer questions
4. Submit
5. View result
6. Run MindTrace
7. View EduTwin
8. Start PathAI
9. Complete practice
10. Reassess
11. Verify mastery update
12. Login teacher
13. Open ClassPulse
14. Verify insight
15. Repeat from a clean session
```

---

## 20. Definition of Done

A release is demo-ready when:
- no blocker bugs;
- core loop passes;
- auth passes;
- teacher/student isolation passes;
- deployment passes;
- AI test set passes agreed threshold;
- demo account is seeded;
- fallback behavior works.
