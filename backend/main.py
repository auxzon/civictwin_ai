"""
CivicTwin AI — Backend API Entrypoint.

Application bootstrap: middleware framework, structured logging, Firebase
Admin initialization, unified exception handling, the health endpoint,
and the versioned v1 API router (mission generation pipeline).
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import firebase_admin
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.v1.router import api_router
from config.settings import get_settings
from core.exceptions import register_exception_handlers
from core.logging import configure_logging, get_logger

settings = get_settings()
configure_logging()
logger = get_logger(__name__)


def _initialize_firebase_admin() -> None:
    """
    Initialize the Firebase Admin SDK exactly once per process.

    Credentials are resolved from GOOGLE_APPLICATION_CREDENTIALS
    (service account JSON), as configured in Decision 2.
    """
    if firebase_admin._apps:  # pylint: disable=protected-access
        logger.info("Firebase Admin SDK already initialized; skipping.")
        return

    if settings.google_application_credentials:
        cred = firebase_admin.credentials.Certificate(settings.google_application_credentials)
        firebase_admin.initialize_app(cred, options={"projectId": settings.firebase_project_id})
        logger.info("Firebase Admin SDK initialized with service account for project '%s'.", settings.firebase_project_id)
    else:
        firebase_admin.initialize_app(options={"projectId": settings.firebase_project_id})
        logger.info("Firebase Admin SDK initialized with Application Default Credentials (ADC) for project '%s'.", settings.firebase_project_id)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    """Application startup/shutdown hook."""
    logger.info("Starting %s [%s]", settings.app_name, settings.environment)
    _initialize_firebase_admin()
    yield
    logger.info("Shutting down %s", settings.app_name)


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_exception_handlers(app)


@app.get("/health", tags=["System"])
async def health_check() -> dict:
    """Liveness probe for Cloud Run and local verification."""
    return {
        "status": "ok",
        "service": settings.app_name,
        "environment": settings.environment,
    }


app.include_router(api_router, prefix=settings.api_v1_prefix)
