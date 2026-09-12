# EduOS — UI/UX Specification

**Version:** 1.0  
**Design Goal:** Clear, modern, student-friendly, trustworthy AI learning experience  
**Platforms:** Flutter mobile + Next.js web  
**Primary Demo:** Grade 10 Mathematics

---

## 1. UX Principles

1. The student should understand what to do next without training.
2. Every important action has visible feedback.
3. AI explanations use student-friendly language.
4. Avoid overwhelming dashboards for students.
5. Teacher dashboards prioritize actionable insight.
6. Use consistent terminology across mobile, web, API, and documentation.
7. Accessibility is a requirement, not decoration.
8. Never make an AI diagnosis visually indistinguishable from a verified fact.
9. Progress should show improvement, not only scores.

---

## 2. Product Terminology

Use these names consistently:

- **EduTwin** — student learning model.
- **MindTrace** — misconception analysis.
- **PathAI** — personalized next action.
- **SmartAssess** — assessment.
- **ClassPulse** — teacher intelligence.

Avoid replacing them randomly with:
- task;
- generic AI;
- magic learning;
- random quiz;
- score bot.

---

## 3. Global Navigation

### Mobile student

Recommended bottom navigation:

```text
Home | Learn | Practice | Tutor | Progress
```

Profile/settings can be accessed from the top-right profile button.

### Web student

Sidebar or top navigation:

```text
Dashboard
Learn
Assessments
Practice
EduTwin
AI Tutor
Progress
Profile
```

### Teacher web

```text
Dashboard
Classes
Assessments
Students
Concepts
Misconceptions
Insights
Profile
```

---

## 4. Student Flow

```text
Welcome
 ↓
Login / Sign Up
 ↓
Student Dashboard
 ↓
Subject
 ↓
Topic / Concept
 ↓
SmartAssess
 ↓
Assessment
 ↓
Results
 ↓
MindTrace
 ↓
EduTwin
 ↓
PathAI
 ↓
Practice
 ↓
Reassessment
 ↓
Updated Progress
```

---

## 5. Screen Specifications

### S01 Welcome

Content:
- EduOS logo;
- concise value proposition;
- Get Started;
- Login.

Avoid:
- large paragraphs;
- unnecessary permissions.

### S02 Login

Fields:
- email/phone depending on implementation;
- password.

States:
- loading;
- invalid credentials;
- network error;
- session expired.

### S03 Student Dashboard

Show:
- greeting;
- overall progress;
- recommended action;
- current weak concept;
- recent activity;
- quick access to Learn, Tutor, Practice, Assess.

Example:

```text
Overall Mastery 68%

Recommended for you
Factorization — 5 min

Continue Learning
Recent Assessment
```

### S04 Subject Detail

Show:
- subject name;
- mastery;
- concept list;
- tests;
- recommended concepts.

Concept card:
- name;
- mastery;
- status;
- action.

### S05 SmartAssess Start

Show:
- assessment title;
- topic;
- number of questions;
- estimated time;
- instructions;
- Start Assessment.

### S06 Assessment

Show:
- question;
- options or answer field;
- progress;
- timer if applicable;
- previous/next;
- submit.

Do not reveal correct answers during a graded assessment.

### S07 Results

Show:
- score;
- correct/incorrect count;
- concept breakdown;
- recommended next action.

Primary CTA:

> Understand My Mistakes

### S08 MindTrace

Show:

```text
Misconception Detected

Concept
Factorization

What may have gone wrong
...

Root Concept
...

Confidence
87%

[Fix This Concept]
```

Use careful language:
- “The response suggests…”
- “Likely misconception…”
when certainty is not high.

### S09 PathAI

Show a short plan:

```text
Your 5-minute recovery plan

1. Explanation — 2 min
2. Worked example — 1 min
3. Practice — 3 questions
4. Reassess
```

### S10 Practice

Show:
- targeted question;
- concept;
- optional hint;
- answer;
- submit;
- feedback.

### S11 Reassessment

Short test focused on the diagnosed concept.

### S12 EduTwin

Show:
- overall mastery;
- subject mastery;
- concept mastery;
- strong concepts;
- weak concepts;
- recent improvement.

Use simple visualizations.

### S13 AI Tutor

Chat interface.

The UI should show:
- current concept context;
- suggested prompts;
- response;
- optional “Practice this” CTA.

### S14 Profile

Show:
- user information;
- grade;
- class;
- settings;
- notifications;
- privacy;
- logout.

---

## 6. Teacher Flow

```text
Teacher Login
 ↓
ClassPulse Dashboard
 ↓
Select Class
 ↓
Class Mastery
 ↓
Weak Concepts
 ↓
Misconceptions
 ↓
Students Needing Attention
 ↓
AI Intervention Recommendation
```

---

## 7. Teacher Dashboard

Primary cards:

```text
Students
Average Mastery
Weak Concepts
Students Needing Attention
```

Concept visualization:

```text
Factorization       43%  Weak
Quadratic Equations 57%  Developing
Linear Equations    84%  Strong
```

Common misconception:

> 14 students show a similar factor-selection error.

Recommendation:

> Consider a targeted revision session.

---

## 8. Responsive Design

Mobile:
- one-column;
- large touch targets;
- bottom navigation;
- short content blocks.

Tablet:
- two-column where useful.

Desktop:
- sidebar;
- cards;
- data tables;
- analytics.

Never simply stretch mobile UI onto desktop.

---

## 9. Accessibility

Minimum:
- readable contrast;
- semantic labels;
- keyboard navigation on web;
- screen-reader labels;
- touch targets large enough for mobile;
- no color-only meaning;
- error messages adjacent to fields;
- scalable text.

---

## 10. Loading States

Every network screen needs:
- skeleton/loading state;
- retry state;
- empty state;
- error state.

Never leave a blank screen while waiting.

---

## 11. Empty States

Examples:

No assessments:

> No assessments available yet. Check again later.

No learning history:

> Complete your first assessment to build your EduTwin.

No teacher data:

> Class insights will appear after students complete assessments.

---

## 12. Error UX

Use human-readable messages.

Bad:
> HTTP 422

Good:
> We couldn't process that answer. Please check it and try again.

AI failure:
> AI analysis is temporarily unavailable. Your assessment is saved. Try analysis again.

---

## 13. Visual Language

Use a consistent educational + technology aesthetic.

Recommended:
- clean white/dark surfaces;
- subtle gradients;
- rounded cards;
- clear hierarchy;
- restrained accent colors;
- meaningful icons.

Avoid:
- excessive neon;
- excessive animation;
- decorative charts;
- fake AI “brain” effects that add no information.

---

## 14. UX Definition of Done

Every screen must have:
- purpose;
- primary CTA;
- loading state;
- empty state where applicable;
- error state;
- success state;
- navigation path;
- accessibility labels;
- responsive behavior.

---

## 15. Critical UX Rule

The user should always understand:

> **Where am I? What happened? Why did it happen? What should I do next?**

That rule applies especially to MindTrace and PathAI.
