"""
Shared pytest fixtures.

Provides an isolated test environment so the test suite never depends on
real Firebase credentials, a real GEMINI_API_KEY, or the developer's local
.env file. All required environment variables are set explicitly here.

The private key below is a throwaway RSA key generated solely for this
test fixture. It is not connected to any real Google Cloud project or
Firebase project, and `firebase_admin.credentials.Certificate` only parses
it locally at init time — no network call is made during these tests.
It is intentionally hardcoded (rather than generated at test time via the
`cryptography` package) so this test suite has no import dependency beyond
what `firebase-admin` itself already requires transitively.
"""

import json
from pathlib import Path

import pytest

_FAKE_PRIVATE_KEY = (
    "-----BEGIN PRIVATE KEY-----\n"
    "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCieohp0ePS0ZR3\n"
    "qrwi/JuKoqyg3Q21hEHQJ+IH2tOXFIyjkImCEHuDaJmHcYp1+iCFitcxSTDvEFN7\n"
    "4l2k44S+5hv9TG7wCFZHglpAiTtC13ZUIrghRb7t27lMOzRnXaamk65/og6ePXv6\n"
    "jtoslC5mMsEFoS2BanqJYAbR2MmoqZ6A4nVY66jYAczIosphzQK3US4lMV6U/2Cq\n"
    "JugpqifMrxjOEVmoYM8U+bNR4fvrv+Rw/3ftMj27ZzW3KlFPMz9UxYaLXhREr+8M\n"
    "g1L4cRykGMHEy+/0Y2QeTnnI/L/dXVelzSBx9McnjFcgnCcV0X7wScOq9Ucsb7Mp\n"
    "OWjiETBHAgMBAAECggEAAYK0uish4s4tz69nxvl+c4HP3ttlqu50wC8tI+T0bgva\n"
    "XODvB/I7e70t6qG/5399hh0eCahd18y/W4z/HhVuOmogQ3207SIrgmGwKus7s+mv\n"
    "gQu+yeYAmh+4Is3M6Gy1+NSxqbnp4eDxDwmWwxUjmbHW514x8pyShBMMLS8TSbA6\n"
    "OE9+7Q6esXxiVUjBJnzMsHFqhoRnomg+IsZuVzyof0ks6J1dE6avN6HGl+4VtYJu\n"
    "K4YBKLo/of1i0QQhm02EL2erYMNAXp93jy01k5AgrqP9f743zXRFCox2jVR1qQeB\n"
    "LWljLiNSpSngh1CJUf5FS7fd2EH5opQOJr1Jcr4v4QKBgQDX9qwSM5NPU0DtkGkQ\n"
    "u+9499lyneq7tB7KwFX4aFJZFtxT8cfxAnuUlAmCjT+0Lu8KulCDHdCkJzHG9EN7\n"
    "CWgfJknSAnJRyLPfHpZ/haRWc5+w47x0JOCPuYJKlpGoVQqhj3T+3zbWCXOrMWEx\n"
    "Thl2LT1dpl28ZvncN8rhtFpHoQKBgQDAmYqc5RWQ5HlajFh3SbRfa6UJ1MgbKd4h\n"
    "cGfOqRm8f8LOMStp0XtSJsarKBfy8+xr0haS29CJjhELb5to5GRcbDkTbycyrSCU\n"
    "w4t0Ngs7bPyZf9RkCqNvgclTthb7LT+XaMBVMxJQ4F3KUK3GCcVblDeQW/nG9Pvb\n"
    "OxxZ35fO5wKBgEmS8OY2ie4RZ+JHO3QHAruMfJkusYSHBaJ/SgqZx8wwHJnAmiRC\n"
    "e0WP9Xlzk4tYHfnipYE1zBnQfIXSO5cUClPqYGXajYXNQXI24oDJT8ZgF7xUqaRL\n"
    "1/E++uNcTn0xk7Ccxff6pZzflXdyGDGK8OOw3+IixnZkAqWCoGyqW8NhAoGARGE/\n"
    "GV0sPvkfLMrPTerZI1ewjMEDGsHOn8is0m6vOIGTxGkopLU/N3eU6YeemR+JPO6m\n"
    "HRX2ACB0ZL8HSkJsb3Ps/71jCVb2Tlru1B+r9TlIpacA3VP5mslVlWb82cjC3xrN\n"
    "znIHerduFTp3t+wYKd+Bqrs8/ypTkQ53jmEYINkCgYEAh1Tbz7plTQuBvQRiLQ3V\n"
    "qkLhIPwLaiMq8QZhNR7tLXEYqfhFGBf0bJMcTihqcg7238SWtqlsq2xluN2hpX+k\n"
    "w/7Mlz18Ma8I0o4RGBj+dJdW2AD33QKlk4KhAI/eBbZjvwXjLI65e+JCwiqY7ARX\n"
    "TdPferxqxJzM7xKSQLVqGDg=\n"
    "-----END PRIVATE KEY-----\n"
)


@pytest.fixture(scope="session")
def fake_service_account(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """Write the static throwaway service-account JSON to a temp file."""
    payload = {
        "type": "service_account",
        "project_id": "civictwin-test",
        "private_key_id": "test-key-id",
        "private_key": _FAKE_PRIVATE_KEY,
        "client_email": "test@civictwin-test.iam.gserviceaccount.com",
        "client_id": "000000000000000000000",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
    }

    path = tmp_path_factory.mktemp("firebase") / "service-account.json"
    path.write_text(json.dumps(payload))
    return path


@pytest.fixture(autouse=True)
def isolated_test_environment(monkeypatch: pytest.MonkeyPatch, fake_service_account: Path) -> None:
    """Set every required environment variable to a safe test value."""
    monkeypatch.setenv("ENVIRONMENT", "development")
    monkeypatch.setenv("APP_NAME", "CivicTwin AI Backend (Test)")
    monkeypatch.setenv("API_V1_PREFIX", "/api/v1")
    monkeypatch.setenv("CORS_ALLOWED_ORIGINS", "http://localhost:5000")
    monkeypatch.setenv("GEMINI_API_KEY", "test-key-not-real")
    monkeypatch.setenv("GEMINI_MODEL", "gemini-2.5-pro")
    monkeypatch.setenv("GEMINI_TEMPERATURE", "0.15")
    monkeypatch.setenv("GEMINI_TOP_P", "0.95")
    monkeypatch.setenv("GOOGLE_APPLICATION_CREDENTIALS", str(fake_service_account))
    monkeypatch.setenv("FIREBASE_PROJECT_ID", "civictwin-test")
    monkeypatch.setenv("AI_CACHE_TTL_HOURS", "2")
    monkeypatch.setenv("RATE_LIMIT_PER_MINUTE", "15")
    monkeypatch.setenv("REQUEST_TIMEOUT_SECONDS", "45")

    # Ensure a stale cached Settings instance from a prior test doesn't leak in.
    from config.settings import get_settings

    get_settings.cache_clear()
