import os
from supabase import create_client

ACCOUNTS={
 'student@example.com':('STUDENT','Student'),
 'teacher@example.com':('TEACHER','Teacher'),
 'parent@example.com':('PARENT','Parent'),
 'principal@example.com':('PRINCIPAL','Principal'),
 'admin@example.com':('ADMIN','Admin'),
}

def main():
 password=os.getenv('EDUOS_DEV_PASSWORD')
 if not password:
  raise SystemExit('Missing EDUOS_DEV_PASSWORD. The agreed development password is not present in configuration; no credential was invented.')
 url=os.getenv('SUPABASE_URL'); key=os.getenv('SUPABASE_SERVICE_ROLE_KEY')
 if not url or not key: raise SystemExit('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.')
 client=create_client(url,key)
 users=client.auth.admin.list_users()
 existing={u.email.lower():u for u in (getattr(users,'users',None) or []) if u.email}
 for email,(role,display_name) in ACCOUNTS.items():
  auth_user=existing.get(email.lower())
  if auth_user is None:
   created=client.auth.admin.create_user({'email':email,'password':password,'email_confirm':True})
   auth_user=getattr(created,'user',None)
  if auth_user is None: raise RuntimeError(f'Could not provision {email}')
  client.table('users').upsert({'auth_user_id':str(auth_user.id),'role':role,'display_name':display_name},on_conflict='auth_user_id').execute()
  print(f'{email} -> {role}')

if __name__=='__main__': main()
