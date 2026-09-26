from supabase import Client, create_client
from app.core.config import settings
admin_supabase: Client = create_client(settings.supabase_url, settings.supabase_service_role_key)
def get_authenticated_client(access_token: str) -> Client:
    client=create_client(settings.supabase_url, settings.supabase_anon_key)
    client.postgrest.auth(access_token)
    return client
