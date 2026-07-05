"""
Native Gemini model binding (EDD V2, Document 04; Decision 1 in DECISIONS.md).

Uses the Gemini Developer API via the `google-genai` SDK, authenticated
with GEMINI_API_KEY. Vertex AI is explicitly out of scope for this
project. This module is a thin, testable wrapper around the SDK call —
prompt construction lives in `services/ai_pipeline.py`.
"""

from google import genai
from google.genai import types

from config.settings import get_settings
from core.logging import get_logger

logger = get_logger(__name__)


class GeminiClient:
    """Thin wrapper around the google-genai Client for structured JSON generation."""

    def __init__(self) -> None:
        settings = get_settings()
        self._model = settings.gemini_model
        self._temperature = settings.gemini_temperature
        self._top_p = settings.gemini_top_p
        self._client = genai.Client(api_key=settings.gemini_api_key)

    async def generate_structured_json(self, prompt: str, response_schema: type) -> str:
        """
        Execute generate_content with strict schema-constrained JSON output.

        Returns the raw JSON text from the model response. Schema
        conformity is enforced by the API itself via `response_schema`;
        callers are still responsible for parsing/validating the result
        (see `services/ai_pipeline.py`).
        """
        response = await self._client.aio.models.generate_content(
            model=self._model,
            contents=prompt,
            config=types.GenerateContentConfig(
                temperature=self._temperature,
                top_p=self._top_p,
                response_mime_type="application/json",
                response_schema=response_schema,
            ),
        )

        if not response.text:
            raise ValueError("Gemini returned an empty response.")

        return response.text
