"""
Unified exception handler and model overrides.

Ensures every error response returned by the API — whether raised
explicitly by a controller or unhandled — has a consistent JSON shape,
and that unhandled exceptions are logged with full context before being
converted into a safe, generic 500 response (never leaking internals to
the client).
"""

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from core.logging import get_logger

logger = get_logger(__name__)


class MissionPipelineError(Exception):
    """Raised when the AI/impact-scoring pipeline fails in a recoverable way."""

    def __init__(self, message: str, *, status_code: int = status.HTTP_502_BAD_GATEWAY) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class BudgetExhaustedError(Exception):
    """Raised when a constituency has no remaining MPLADS budget."""

    def __init__(self, constituency_id: str) -> None:
        super().__init__(f"Allocated pool budget exhausted for '{constituency_id}'.")
        self.constituency_id = constituency_id


class ConstituencyNotFoundError(Exception):
    """Raised when a requested constituency_id does not exist in Firestore."""

    def __init__(self, constituency_id: str) -> None:
        super().__init__(f"Constituency identifier invalid: '{constituency_id}'.")
        self.constituency_id = constituency_id


def _error_body(message: str, *, code: str) -> dict:
    return {"error": {"code": code, "message": message}}


def register_exception_handlers(app: FastAPI) -> None:
    """Attach all unified exception handlers to the FastAPI app instance."""

    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_body(str(exc.detail), code="http_error"),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=_error_body("Request validation failed.", code="validation_error")
            | {"details": exc.errors()},
        )

    @app.exception_handler(ConstituencyNotFoundError)
    async def constituency_not_found_handler(
        _: Request, exc: ConstituencyNotFoundError
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content=_error_body(str(exc), code="constituency_not_found"),
        )

    @app.exception_handler(BudgetExhaustedError)
    async def budget_exhausted_handler(_: Request, exc: BudgetExhaustedError) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content=_error_body(str(exc), code="budget_exhausted"),
        )

    @app.exception_handler(MissionPipelineError)
    async def mission_pipeline_error_handler(_: Request, exc: MissionPipelineError) -> JSONResponse:
        logger.error("Mission pipeline failure: %s", exc.message)
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_body(exc.message, code="mission_pipeline_error"),
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(_: Request, exc: Exception) -> JSONResponse:
        logger.exception("Unhandled exception: %s", exc)
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=_error_body("An unexpected error occurred.", code="internal_error"),
        )
