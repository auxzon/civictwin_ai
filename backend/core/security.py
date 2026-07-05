"""
Firebase JWT Token validation interceptor.

Per Decision 2 (DECISIONS.md), authentication uses the Firebase Admin SDK
(`firebase_admin.auth.verify_id_token`). The literal code sample in EDD V2
Document 03 used `google.oauth2.id_token.verify_oauth2_token`, which
validates Google OAuth2 ID tokens — not Firebase Auth ID tokens — and was
an inconsistency in the source document. This module is the corrected,
official implementation.
"""

from fastapi import Header, HTTPException, status
from firebase_admin import auth
from firebase_admin.auth import ExpiredIdTokenError, InvalidIdTokenError, RevokedIdTokenError

from core.logging import get_logger

logger = get_logger(__name__)


def verify_firebase_token(authorization: str = Header(...)) -> str:
    """
    FastAPI dependency that validates a Firebase Auth Bearer token.

    Returns the authenticated user's Firebase UID on success. Raises
    HTTPException(401) on any validation failure, and HTTPException(400)
    if the Authorization header is malformed.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Authorization header must follow the 'Bearer <token>' schema.",
        )

    token = authorization.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Bearer token must not be empty.",
        )

    try:
        decoded_token = auth.verify_id_token(token, clock_skew_seconds=10)
    except (InvalidIdTokenError, ExpiredIdTokenError, RevokedIdTokenError) as exc:
        logger.warning("Firebase token validation failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid, expired, or revoked authentication token.",
        ) from exc
    except Exception as exc:  # noqa: BLE001 - defensive: SDK may raise other errors
        logger.error("Unexpected error during token validation: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token validation failed.",
        ) from exc

    uid = decoded_token.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token did not contain a valid user identifier.",
        )

    return uid
