# EduOS — Security, Privacy & K–12 Safety Specification

**Version:** 1.0  
**Audience:** Engineering, product, AI, QA  
**Scope:** Student, teacher, assessment, AI, and educational content data

---

## 1. Security Objective

EduOS handles education data belonging to minors and therefore must treat student information as sensitive.

The MVP must implement:
- secure authentication;
- authorization;
- least privilege;
- encrypted transport;
- secret management;
- minimal data collection;
- safe AI handling;
- auditability.

This document is an engineering specification, not legal advice. Production deployment must be reviewed against applicable laws, school policies, contracts, and local requirements.

---

## 2. Data Classification

### Public
- public product information;
- public educational content intentionally published.

### Internal
- system configuration;
- non-sensitive operational metrics.

### Student-sensitive
- student profile;
- grades;
- assessment answers;
- mastery;
- misconceptions;
- learning history.

### Highly sensitive credentials
- passwords;
- tokens;
- API keys;
- service credentials.

Credentials must never be stored in ordinary application records.

---

## 3. Authentication

Use Supabase Auth or an equivalent secure identity provider.

Requirements:
- secure session handling;
- token validation;
- expiration;
- logout;
- password reset through provider;
- no plaintext passwords.

---

## 4. Authorization

Roles:

```text
STUDENT
TEACHER
ADMIN
```

### Student

Can access:
- own profile;
- own assessments;
- own mastery;
- own learning history;
- own tutor conversations.

Cannot access:
- another student's data;
- teacher analytics;
- private school data.

### Teacher

Can access:
- assigned classes;
- assigned students;
- aggregated classroom insights.

Cannot access:
- unrelated school/class data.

### Admin

Only authorized administrative operations.

---

## 5. Resource Ownership

Never trust a client-provided ID.

Example:

```text
GET /students/{id}
```

Backend must verify the authenticated user can access that student.

---

## 6. Row-Level Security

Supabase RLS should provide defense in depth.

Examples:
- student can read own mastery;
- teacher can read students in assigned classes;
- user cannot update another user's role.

Backend authorization remains required.

---

## 7. Transport Security

Production:
- HTTPS only;
- secure cookies/session strategy where applicable;
- HSTS where appropriate.

Never send secrets through query parameters.

---

## 8. Secret Management

Secrets must live in:
- hosting provider secret manager;
- environment variables;
- secure CI secrets.

Never:
- commit `.env`;
- place API keys in Flutter;
- place API keys in Next.js client bundle;
- put service-role keys in public code.

---

## 9. AI Privacy

Only send the minimum context needed.

Example:
- grade;
- concept;
- question;
- answer;
- relevant learning evidence.

Do not send:
- unrelated personal information;
- another student's information;
- internal credentials.

---

## 10. AI Safety

AI must not:
- reveal private student information;
- expose system prompts;
- make disciplinary decisions;
- label students in harmful ways;
- present uncertain diagnoses as facts;
- replace teacher judgment;
- generate inappropriate content for minors.

---

## 11. Student-Facing Language

Avoid stigmatizing labels such as:
- “bad student”;
- “weak student”;
- “failed learner.”

Prefer:
- “concept needs more practice”;
- “developing mastery”;
- “recent responses suggest…”

---

## 12. Human Oversight

Teacher-facing AI recommendations must be recommendations.

Example:

> “14 students show a similar misconception pattern. Consider a targeted revision session.”

Not:

> “The system has decided these students must attend remedial class.”

---

## 13. Consent and Data Governance

Production implementation must define:
- who controls school data;
- consent/authorization requirements;
- data retention;
- deletion;
- student/guardian rights where applicable;
- school contracts;
- AI provider data processing terms.

For hackathon demo:
- use synthetic/demo students;
- avoid real minor data;
- do not upload real student records.

---

## 14. File Security

For uploaded documents:
- validate MIME type;
- validate file size;
- reject unsupported formats;
- generate safe storage names;
- do not trust filenames;
- scan files in production;
- restrict access;
- do not expose storage buckets publicly unless intentionally public.

---

## 15. Input Security

Validate:
- string length;
- JSON schema;
- IDs;
- file size;
- allowed enum values.

Protect against:
- SQL injection;
- XSS;
- prompt injection;
- oversized requests;
- malicious files;
- abusive AI requests.

Use parameterized queries/ORM.

---

## 16. Prompt Injection Defense

Educational documents and student text may contain instructions such as:

> “Ignore previous instructions…”

The system must treat retrieved/user content as untrusted data.

System instructions must remain authoritative.

---

## 17. Logging

Never log:
- passwords;
- tokens;
- API keys.

Minimize:
- student answer content;
- personal details.

Use request IDs to correlate errors.

---

## 18. Rate Limiting

Rate limit:
- login attempts;
- tutor chat;
- MindTrace;
- document upload;
- RAG queries.

Limits should be appropriate to user role and product needs.

---

## 19. Abuse Prevention

Monitor:
- repeated AI calls;
- oversized uploads;
- suspicious account activity;
- endpoint enumeration;
- unauthorized access attempts.

---

## 20. Data Retention

MVP should retain only data needed to:
- operate;
- demonstrate;
- evaluate.

Production must establish documented retention periods.

---

## 21. Data Deletion

Architecture should support deletion of:
- account;
- profile;
- assessment history;
- uploaded documents;
- AI history where applicable.

Deletion must account for:
- database;
- storage;
- vector index;
- logs;
- backups;
- third-party services.

---

## 22. Security Testing

Test:
- role bypass;
- IDOR;
- direct object access;
- token misuse;
- expired sessions;
- upload abuse;
- prompt injection;
- XSS;
- invalid input;
- rate limits.

---

## 23. Security Definition of Done

Before demo:
- no secrets committed;
- production uses HTTPS;
- roles enforced;
- student data isolated;
- service-role key server-only;
- error messages do not leak internals;
- test accounts use synthetic data;
- AI prompts contain no unnecessary PII.

---

## 24. K–12 Safety Principle

> **EduOS should help students learn without turning AI predictions into permanent labels about children.**

Learning states are evidence-based, revisable, and contextual.
