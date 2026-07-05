"""
Centralized application configuration.

Loads and validates all environment-driven settings for the CivicTwin AI
backend using pydantic-settings. This is the single source of truth for
configuration values consumed across the application — no module should
read `os.environ` directly.

Architectural notes:
    - Decision 1 (frozen): Gemini access is via the Gemini Developer API
      (`google-genai` library, API-key auth). Vertex AI is explicitly
      excluded from this project.
    - Decision 2 (frozen): Firebase Admin SDK is the sole authentication
      mechanism (`firebase_admin.auth.verify_id_token`).
"""

from functools import lru_cache
from typing import Annotated

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    """Application-wide settings sourced from environment variables / .env."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # --- Application ---
    environment: str = Field(default="development", alias="ENVIRONMENT")
    app_name: str = Field(default="CivicTwin AI Backend", alias="APP_NAME")
    api_v1_prefix: str = Field(default="/api/v1", alias="API_V1_PREFIX")
    cors_allowed_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=list, alias="CORS_ALLOWED_ORIGINS"
    )

    # --- Gemini Developer API (Decision 1) ---
    gemini_api_key: str = Field(default="", alias="GEMINI_API_KEY")
    gemini_model: str = Field(default="gemini-2.5-pro", alias="GEMINI_MODEL")
    gemini_temperature: float = Field(default=0.15, alias="GEMINI_TEMPERATURE")
    gemini_top_p: float = Field(default=0.95, alias="GEMINI_TOP_P")

    # --- Firebase Admin SDK (Decision 2) ---
    google_application_credentials: str = Field(
        default="",
        alias="GOOGLE_APPLICATION_CREDENTIALS",
    )
    firebase_project_id: str = Field(default="", alias="FIREBASE_PROJECT_ID")

    # --- Cache Configuration (ai_cache collection) ---
    ai_cache_ttl_hours: int = Field(default=2, alias="AI_CACHE_TTL_HOURS")

    # --- Rate Limiting ---
    rate_limit_per_minute: int = Field(default=15, alias="RATE_LIMIT_PER_MINUTE")

    # --- Request Timeout ---
    request_timeout_seconds: int = Field(default=45, alias="REQUEST_TIMEOUT_SECONDS")

    @field_validator("cors_allowed_origins", mode="before")
    @classmethod
    def _split_csv_origins(cls, value: object) -> list[str]:
        """Allow CORS_ALLOWED_ORIGINS to be provided as a comma-separated string."""
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value  # type: ignore[return-value]

    @field_validator("cors_allowed_origins", mode="after")
    @classmethod
    def _require_explicit_origins(cls, value: list[str]) -> list[str]:
        """
        Fail fast if no CORS origins are configured.

        Audit finding F1: wildcard ("*") CORS combined with credentialed
        requests is a live security misconfiguration. This app must never
        fall back to allow-all; an empty/missing CORS_ALLOWED_ORIGINS is
        treated as a configuration error, not a permissive default.
        """
        if not value:
            raise ValueError(
                "CORS_ALLOWED_ORIGINS must be set to a non-empty comma-separated "
                "list of explicit origins. Wildcard ('*') origins are not "
                "permitted. See .env.example."
            )
        if "*" in value:
            raise ValueError(
                "CORS_ALLOWED_ORIGINS must not contain '*'. List explicit "
                "origins only (e.g. https://app.civictwin.ai)."
            )
        return value

    @property
    def is_production(self) -> bool:
        return self.environment.lower() == "production"


@lru_cache
def get_settings() -> Settings:
    """
    Return a cached Settings instance.

    Cached via lru_cache so environment parsing/validation happens once per
    process, and the same instance is reused across dependency injections.
    """
    return Settings()
