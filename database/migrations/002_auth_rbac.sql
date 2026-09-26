-- EduOS authentication/RBAC foundation
-- Applies to the existing schema from 001_initial_schema.sql.
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'PARENT';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'PRINCIPAL';

CREATE TABLE IF NOT EXISTS public.parent_student_links(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(parent_user_id,student_id)
);

CREATE TABLE IF NOT EXISTS public.principal_profiles(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  school_id uuid NOT NULL REFERENCES public.schools(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.prevent_user_role_self_assignment()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=''
AS $$ BEGIN
  IF TG_OP='INSERT' AND NEW.role IS NULL THEN RAISE EXCEPTION 'Application role is required'; END IF;
  IF TG_OP='UPDATE' AND NEW.role IS DISTINCT FROM OLD.role THEN RAISE EXCEPTION 'Application roles may only be changed by trusted provisioning'; END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_prevent_user_role_self_assignment ON public.users;
CREATE TRIGGER trg_prevent_user_role_self_assignment BEFORE INSERT OR UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.prevent_user_role_self_assignment();

CREATE SCHEMA IF NOT EXISTS private;
CREATE OR REPLACE FUNCTION private.current_app_role()
RETURNS public.user_role LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT u.role FROM public.users u WHERE u.auth_user_id=(select auth.uid()) LIMIT 1 $$;
CREATE OR REPLACE FUNCTION private.current_app_user_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT u.id FROM public.users u WHERE u.auth_user_id=(select auth.uid()) LIMIT 1 $$;
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT COALESCE((select private.current_app_role())='ADMIN',false) $$;
CREATE OR REPLACE FUNCTION private.is_teacher()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT COALESCE((select private.current_app_role())='TEACHER',false) $$;
CREATE OR REPLACE FUNCTION private.is_principal()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT COALESCE((select private.current_app_role())='PRINCIPAL',false) $$;
CREATE OR REPLACE FUNCTION private.is_parent()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT COALESCE((select private.current_app_role())='PARENT',false) $$;
CREATE OR REPLACE FUNCTION private.is_student()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $$ SELECT COALESCE((select private.current_app_role())='STUDENT',false) $$;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_class_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mindtrace_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_mastery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mastery_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_mistakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_student_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.principal_profiles ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.users,public.parent_student_links,public.principal_profiles FROM anon,authenticated;
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT ON public.parent_student_links,public.principal_profiles TO authenticated;

DROP POLICY IF EXISTS users_self_read ON public.users;
CREATE POLICY users_self_read ON public.users FOR SELECT TO authenticated
USING ((select private.is_admin()) OR auth_user_id=(select auth.uid()));

DROP POLICY IF EXISTS parent_links_self_read ON public.parent_student_links;
CREATE POLICY parent_links_self_read ON public.parent_student_links FOR SELECT TO authenticated
USING ((select private.is_admin()) OR parent_user_id=(select private.current_app_user_id()));

DROP POLICY IF EXISTS principal_profile_self_read ON public.principal_profiles;
CREATE POLICY principal_profile_self_read ON public.principal_profiles FOR SELECT TO authenticated
USING ((select private.is_admin()) OR user_id=(select private.current_app_user_id()));

REVOKE ALL ON public.students,public.teachers,public.schools,public.classes,public.class_memberships,public.teacher_class_memberships,public.assessments,public.assessment_questions,public.assessment_attempts,public.assessment_answers,public.mindtrace_analyses,public.student_mastery,public.mastery_history,public.student_mistakes,public.recommendations,public.learning_events FROM anon;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.students,public.teachers,public.schools,public.classes,public.class_memberships,public.teacher_class_memberships,public.assessments,public.assessment_questions,public.assessment_attempts,public.assessment_answers,public.mindtrace_analyses,public.student_mastery,public.mastery_history,public.student_mistakes,public.recommendations,public.learning_events TO authenticated;

DROP POLICY IF EXISTS students_access ON public.students;
CREATE POLICY students_access ON public.students FOR SELECT TO authenticated
USING ((select private.is_admin()) OR user_id=(select private.current_app_user_id())
 OR ((select private.is_parent()) AND id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id())))
 OR ((select private.is_teacher()) AND id IN (SELECT cm.student_id FROM public.class_memberships cm JOIN public.teacher_class_memberships tm ON tm.class_id=cm.class_id JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id())))
 OR ((select private.is_principal()) AND school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id()))));

DROP POLICY IF EXISTS teachers_access ON public.teachers;
CREATE POLICY teachers_access ON public.teachers FOR SELECT TO authenticated
USING ((select private.is_admin()) OR user_id=(select private.current_app_user_id())
 OR school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id()) AND (select private.is_principal())));

DROP POLICY IF EXISTS schools_access ON public.schools;
CREATE POLICY schools_access ON public.schools FOR SELECT TO authenticated
USING ((select private.is_admin()) OR id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id()))
 OR id IN (SELECT s.school_id FROM public.students s WHERE s.user_id=(select private.current_app_user_id()))
 OR id IN (SELECT t.school_id FROM public.teachers t WHERE t.user_id=(select private.current_app_user_id())));

DROP POLICY IF EXISTS classes_access ON public.classes;
CREATE POLICY classes_access ON public.classes FOR SELECT TO authenticated
USING ((select private.is_admin()) OR id IN (SELECT tm.class_id FROM public.teacher_class_memberships tm JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id()))
 OR id IN (SELECT cm.class_id FROM public.class_memberships cm JOIN public.students s ON s.id=cm.student_id WHERE s.user_id=(select private.current_app_user_id()))
 OR school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id()) AND (select private.is_principal()))
 OR id IN (SELECT cm.class_id FROM public.class_memberships cm WHERE (select private.is_parent()) AND cm.student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id()))));

DROP POLICY IF EXISTS class_memberships_access ON public.class_memberships;
CREATE POLICY class_memberships_access ON public.class_memberships FOR SELECT TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR class_id IN (SELECT tm.class_id FROM public.teacher_class_memberships tm JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id()))
 OR class_id IN (SELECT c.id FROM public.classes c WHERE c.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id())))
 OR ((select private.is_parent()) AND student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id()))));

DROP POLICY IF EXISTS teacher_memberships_access ON public.teacher_class_memberships;
CREATE POLICY teacher_memberships_access ON public.teacher_class_memberships FOR SELECT TO authenticated
USING ((select private.is_admin()) OR teacher_id IN (SELECT id FROM public.teachers WHERE user_id=(select auth.uid()))
 OR class_id IN (SELECT c.id FROM public.classes c WHERE c.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id()))));

DROP POLICY IF EXISTS assessments_read ON public.assessments;
CREATE POLICY assessments_read ON public.assessments FOR SELECT TO authenticated
USING ((select private.is_admin()) OR status='PUBLISHED' OR (select private.is_teacher()) OR (select private.is_principal()));

DROP POLICY IF EXISTS assessment_questions_read ON public.assessment_questions;
CREATE POLICY assessment_questions_read ON public.assessment_questions FOR SELECT TO authenticated
USING ((select private.is_admin()) OR assessment_id IN (SELECT id FROM public.assessments WHERE status='PUBLISHED') OR (select private.is_teacher()) OR (select private.is_principal()));

DROP POLICY IF EXISTS attempts_access ON public.assessment_attempts;
CREATE POLICY attempts_access ON public.assessment_attempts FOR ALL TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR (select private.is_teacher()) OR (select private.is_principal()))
WITH CHECK ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid())));

DROP POLICY IF EXISTS answers_access ON public.assessment_answers;
CREATE POLICY answers_access ON public.assessment_answers FOR ALL TO authenticated
USING ((select private.is_admin()) OR attempt_id IN (SELECT aa.id FROM public.assessment_attempts aa JOIN public.students s ON s.id=aa.student_id WHERE s.user_id=(select auth.uid()))
 OR (select private.is_teacher()) OR (select private.is_principal()))
WITH CHECK ((select private.is_admin()) OR attempt_id IN (SELECT aa.id FROM public.assessment_attempts aa JOIN public.students s ON s.id=aa.student_id WHERE s.user_id=(select auth.uid())));

DROP POLICY IF EXISTS mastery_access ON public.student_mastery;
CREATE POLICY mastery_access ON public.student_mastery FOR SELECT TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR ((select private.is_parent()) AND student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id())))
 OR ((select private.is_teacher()) AND student_id IN (SELECT cm.student_id FROM public.class_memberships cm JOIN public.teacher_class_memberships tm ON tm.class_id=cm.class_id JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id())))
 OR ((select private.is_principal()) AND student_id IN (SELECT s.id FROM public.students s WHERE s.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id())))));

DROP POLICY IF EXISTS history_access ON public.mastery_history;
CREATE POLICY history_access ON public.mastery_history FOR SELECT TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR ((select private.is_parent()) AND student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id())))
 OR ((select private.is_teacher()) AND student_id IN (SELECT cm.student_id FROM public.class_memberships cm JOIN public.teacher_class_memberships tm ON tm.class_id=cm.class_id JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id())))
 OR ((select private.is_principal()) AND student_id IN (SELECT s.id FROM public.students s WHERE s.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id())))));

DROP POLICY IF EXISTS mistakes_access ON public.student_mistakes;
CREATE POLICY mistakes_access ON public.student_mistakes FOR SELECT TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR ((select private.is_parent()) AND student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id())))
 OR ((select private.is_teacher()) AND student_id IN (SELECT cm.student_id FROM public.class_memberships cm JOIN public.teacher_class_memberships tm ON tm.class_id=cm.class_id JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id())))
 OR ((select private.is_principal()) AND student_id IN (SELECT s.id FROM public.students s WHERE s.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id())))));

DROP POLICY IF EXISTS recommendations_access ON public.recommendations;
CREATE POLICY recommendations_access ON public.recommendations FOR SELECT TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR ((select private.is_parent()) AND student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id())))
 OR ((select private.is_teacher()) AND student_id IN (SELECT cm.student_id FROM public.class_memberships cm JOIN public.teacher_class_memberships tm ON tm.class_id=cm.class_id JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id())))
 OR ((select private.is_principal()) AND student_id IN (SELECT s.id FROM public.students s WHERE s.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id())))));

DROP POLICY IF EXISTS learning_events_access ON public.learning_events;
CREATE POLICY learning_events_access ON public.learning_events FOR SELECT TO authenticated
USING ((select private.is_admin()) OR student_id IN (SELECT id FROM public.students WHERE user_id=(select auth.uid()))
 OR ((select private.is_parent()) AND student_id IN (SELECT student_id FROM public.parent_student_links WHERE parent_user_id=(select private.current_app_user_id())))
 OR ((select private.is_teacher()) AND student_id IN (SELECT cm.student_id FROM public.class_memberships cm JOIN public.teacher_class_memberships tm ON tm.class_id=cm.class_id JOIN public.teachers t ON t.id=tm.teacher_id WHERE t.user_id=(select private.current_app_user_id())))
 OR ((select private.is_principal()) AND student_id IN (SELECT s.id FROM public.students s WHERE s.school_id IN (SELECT school_id FROM public.principal_profiles WHERE user_id=(select private.current_app_user_id())))));

DROP POLICY IF EXISTS mindtrace_access ON public.mindtrace_analyses;
CREATE POLICY mindtrace_access ON public.mindtrace_analyses FOR SELECT TO authenticated
USING ((select private.is_admin()) OR assessment_answer_id IN (SELECT a.id FROM public.assessment_answers a JOIN public.assessment_attempts t ON t.id=a.attempt_id JOIN public.students s ON s.id=t.student_id WHERE s.user_id=(select auth.uid()))
 OR (select private.is_teacher()) OR (select private.is_principal()));

REVOKE EXECUTE ON FUNCTION public.prevent_user_role_self_assignment() FROM public,anon,authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA private FROM public,anon,authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA private FROM public,anon,authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.current_app_role(),private.current_app_user_id(),private.is_admin(),private.is_teacher(),private.is_principal(),private.is_parent(),private.is_student() TO authenticated;
