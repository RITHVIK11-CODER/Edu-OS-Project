from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"

    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str

    database_url: str | None = None

    llm_provider: str = "gemini"
    gemini_api_key: str | None = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()