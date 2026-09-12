-- EduOS Initial Database Schema
-- PostgreSQL / Supabase
-- Migration: 001_initial_schema

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;


-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE user_role AS ENUM (
    'STUDENT',
    'TEACHER',
    'ADMIN'
);


-- ============================================================
-- USERS
-- ============================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE NOT NULL,
    role user_role NOT NULL,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- SCHOOLS
-- ============================================================

CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- STUDENTS
-- ============================================================

CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    grade INT,
    section TEXT,
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT students_grade_check
        CHECK (grade IS NULL OR grade BETWEEN 1 AND 12)
);


-- ============================================================
-- TEACHERS
-- ============================================================

CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- CLASSES
-- ============================================================

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    name TEXT,
    grade INT,
    section TEXT,
    academic_year TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT classes_grade_check
        CHECK (grade IS NULL OR grade BETWEEN 1 AND 12)
);


-- ============================================================
-- CLASS MEMBERSHIPS
-- ============================================================

CREATE TABLE class_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (class_id, student_id)
);


-- ============================================================
-- TEACHER CLASS MEMBERSHIPS
-- ============================================================

CREATE TABLE teacher_class_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    role TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- SUBJECTS
-- ============================================================

CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    grade INT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- CONCEPTS
-- ============================================================

CREATE TABLE concepts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    parent_concept_id UUID REFERENCES concepts(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    difficulty INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT concepts_difficulty_check
        CHECK (difficulty IS NULL OR difficulty BETWEEN 1 AND 5)
);


-- ============================================================
-- CONCEPT PREREQUISITES
-- ============================================================

CREATE TABLE concept_prerequisites (
    concept_id UUID NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    prerequisite_concept_id UUID NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    weight NUMERIC(5,2),

    PRIMARY KEY (concept_id, prerequisite_concept_id),

    CONSTRAINT concept_prerequisite_self_check
        CHECK (concept_id <> prerequisite_concept_id)
);


-- ============================================================
-- QUESTIONS
-- ============================================================

CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    concept_id UUID NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL,
    options JSONB,
    correct_answer JSONB NOT NULL,
    explanation TEXT,
    difficulty INT,
    source_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT questions_difficulty_check
        CHECK (difficulty IS NULL OR difficulty BETWEEN 1 AND 5)
);


-- ============================================================
-- ASSESSMENTS
-- ============================================================

CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    grade INT NOT NULL,
    description TEXT,
    duration_seconds INT,
    status TEXT NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT assessments_grade_check
        CHECK (grade BETWEEN 1 AND 12)
);


-- ============================================================
-- ASSESSMENT QUESTIONS
-- ============================================================

CREATE TABLE assessment_questions (
    assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    sequence INT NOT NULL,

    PRIMARY KEY (assessment_id, question_id),

    UNIQUE (assessment_id, sequence)
);


-- ============================================================
-- ASSESSMENT ATTEMPTS
-- ============================================================

CREATE TABLE assessment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    score NUMERIC(6,2),
    status TEXT NOT NULL DEFAULT 'IN_PROGRESS'
);


-- ============================================================
-- ASSESSMENT ANSWERS
-- ============================================================

CREATE TABLE assessment_answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES assessment_attempts(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    answer JSONB,
    is_correct BOOLEAN,
    time_spent_seconds INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (attempt_id, question_id)
);


-- ============================================================
-- MINDTRACE ANALYSES
-- ============================================================

CREATE TABLE mindtrace_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_answer_id UUID NOT NULL
        REFERENCES assessment_answers(id) ON DELETE CASCADE,

    misconception_code TEXT,
    misconception_label TEXT,
    root_cause TEXT,
    evidence TEXT,
    confidence NUMERIC(5,4),

    model_name TEXT,
    prompt_version TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- STUDENT MASTERY
-- ============================================================

CREATE TABLE student_mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    concept_id UUID NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,

    mastery_score NUMERIC(5,2) NOT NULL DEFAULT 0,
    confidence NUMERIC(5,4),

    last_assessed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (student_id, concept_id),

    CONSTRAINT mastery_score_check
        CHECK (mastery_score BETWEEN 0 AND 100)
);


-- ============================================================
-- MASTERY HISTORY
-- ============================================================

CREATE TABLE mastery_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    concept_id UUID NOT NULL REFERENCES concepts(id) ON DELETE CASCADE,
    previous_score NUMERIC(5,2),
    new_score NUMERIC(5,2) NOT NULL,
    reason TEXT,
    source_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- STUDENT MISTAKES
-- ============================================================

CREATE TABLE student_mistakes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id) ON DELETE SET NULL,
    concept_id UUID REFERENCES concepts(id) ON DELETE SET NULL,
    misconception_code TEXT,
    occurrence_count INT NOT NULL DEFAULT 1,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RECOMMENDATIONS
-- ============================================================

CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    concept_id UUID REFERENCES concepts(id) ON DELETE SET NULL,

    recommendation_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    priority INT,
    reason TEXT,

    status TEXT NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);


-- ============================================================
-- LEARNING EVENTS
-- ============================================================

CREATE TABLE learning_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,

    event_type TEXT NOT NULL,
    concept_id UUID REFERENCES concepts(id) ON DELETE SET NULL,

    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- DOCUMENTS
-- ============================================================

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    source_type TEXT,
    source_uri TEXT,
    subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
    grade INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- DOCUMENT CHUNKS
-- ============================================================

CREATE TABLE document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,

    chunk_index INT NOT NULL,
    content TEXT NOT NULL,

    embedding VECTOR(768),

    metadata JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (document_id, chunk_index)
);


-- ============================================================
-- AI ANALYSIS RECORDS
-- ============================================================

CREATE TABLE ai_analysis_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    student_id UUID REFERENCES students(id) ON DELETE CASCADE,

    analysis_type TEXT NOT NULL,
    input_reference JSONB,
    output JSONB NOT NULL,

    model_name TEXT,
    prompt_version TEXT,
    confidence NUMERIC(5,4),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_students_school
    ON students(school_id);

CREATE INDEX idx_classes_school
    ON classes(school_id);

CREATE INDEX idx_class_memberships_student
    ON class_memberships(student_id);

CREATE INDEX idx_teacher_memberships_teacher
    ON teacher_class_memberships(teacher_id);

CREATE INDEX idx_concepts_subject
    ON concepts(subject_id);

CREATE INDEX idx_questions_concept
    ON questions(concept_id);

CREATE INDEX idx_assessment_questions_assessment
    ON assessment_questions(assessment_id);

CREATE INDEX idx_attempts_student
    ON assessment_attempts(student_id);

CREATE INDEX idx_answers_attempt
    ON assessment_answers(attempt_id);

CREATE INDEX idx_mindtrace_answer
    ON mindtrace_analyses(assessment_answer_id);

CREATE INDEX idx_mastery_student
    ON student_mastery(student_id);

CREATE INDEX idx_mastery_concept
    ON student_mastery(concept_id);

CREATE INDEX idx_mistakes_student
    ON student_mistakes(student_id);

CREATE INDEX idx_recommendations_student
    ON recommendations(student_id);

CREATE INDEX idx_learning_events_student
    ON learning_events(student_id);

CREATE INDEX idx_documents_subject
    ON documents(subject_id);

CREATE INDEX idx_document_chunks_document
    ON document_chunks(document_id);

CREATE INDEX idx_ai_analysis_student
    ON ai_analysis_records(student_id);


-- ============================================================
-- VECTOR INDEX
-- ============================================================

CREATE INDEX idx_document_chunks_embedding
    ON document_chunks
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);