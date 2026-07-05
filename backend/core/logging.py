"""
Structured logging configuration.

Configures Python's standard `logging` module to emit structured JSON log
records compatible with Google Cloud Logging's structured log ingestion,
per the architecture's "Cloud Logging & Trace (Structured JSON Audit Logs)"
requirement.

This module only establishes the logging pipeline itself. Request-scoped
trace/audit interceptors (e.g. attaching request IDs, user IDs) are
implemented alongside the request-handling controllers in Phase 2.
"""

import json
import logging
import sys
from datetime import UTC, datetime
from typing import Any

from config.settings import get_settings


class StructuredJSONFormatter(logging.Formatter):
    """Formats log records as single-line JSON objects."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "severity": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "timestamp": datetime.now(UTC).isoformat(),
        }

        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)

        # Allow callers to attach structured extras via `extra={"ctx": {...}}`
        extra_ctx = getattr(record, "ctx", None)
        if extra_ctx:
            payload["context"] = extra_ctx

        return json.dumps(payload, default=str)


def configure_logging() -> None:
    """
    Initialize the root logger with a structured JSON stream handler.

    Idempotent: safe to call multiple times (e.g. in tests) without
    duplicating handlers.
    """
    settings = get_settings()
    root_logger = logging.getLogger()

    if any(isinstance(h, logging.StreamHandler) for h in root_logger.handlers):
        return  # Already configured.

    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setFormatter(StructuredJSONFormatter())

    root_logger.addHandler(handler)
    root_logger.setLevel(logging.DEBUG if not settings.is_production else logging.INFO)


def get_logger(name: str) -> logging.Logger:
    """Return a module-scoped logger. Call `configure_logging()` once at startup first."""
    return logging.getLogger(name)
