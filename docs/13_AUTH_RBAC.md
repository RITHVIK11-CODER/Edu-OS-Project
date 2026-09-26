# EduOS Authentication & RBAC Foundation

Authentication source: **Supabase Auth only**.

## Identity flow

```
auth.users.id -> public.users.auth_user_id -> public.users.role
```

Allowed application roles are exactly: STUDENT, TEACHER, PARENT, PRINCIPAL, ADMIN.

The browser never supplies or selects an authoritative role. `GET /api/v1/auth/me` validates the Supabase bearer token and resolves role from `public.users`.

## Web session

The browser uses one Supabase client with persisted sessions and automatic token refresh. The application never writes a custom access token to localStorage. Auth state is restored with Supabase `getSession()` plus `onAuthStateChange`, then the application user is loaded from the backend.

## Backend

FastAPI dependencies provide `get_current_user()`, `require_role()`, and `require_roles()`. Protected endpoints derive identity from the validated Supabase JWT and role from `public.users`.

There is no backend login endpoint and no custom application token.

## Role provisioning

Development accounts are provisioned by `scripts/provision_dev_users.py` using the Supabase service-role key on a trusted machine. The password is read only from `EDUOS_DEV_PASSWORD`; the script stops if it is missing and never stores the password in `public.users`.

## Database security

Migration `002_auth_rbac.sql` adds PARENT and PRINCIPAL, parent-child and principal-school mappings, protects application roles from client writes, enables RLS on identity/learning tables, and grants only the access required by authenticated callers. Service-role credentials remain server-only.

## Required development accounts

- student@example.com -> STUDENT
- teacher@example.com -> TEACHER
- parent@example.com -> PARENT
- principal@example.com -> PRINCIPAL
- admin@example.com -> ADMIN

The five accounts cannot be verified or provisioned until the Supabase project is connected and `EDUOS_DEV_PASSWORD` is supplied.
