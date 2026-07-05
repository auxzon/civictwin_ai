"""
Firestore database seeding script.

Populates a clean or existing Firestore instance with the mock operational
dataset defined in `mock_data.py`, matching the exact schema in EDD V2
Document 02 (system_config, constituencies, wards subcollection, signals
subcollection).

Usage:
    Configure GOOGLE_APPLICATION_CREDENTIALS and FIREBASE_PROJECT_ID in `.env`,
    then run:
    python -m scripts.seed_database

Design notes:
    - Idempotent: uses deterministic document IDs from the mock dataset, so
      re-running this script overwrites (not duplicates) the same records.
    - Firestore GeoPoint / SERVER_TIMESTAMP conversions are handled here so
      `mock_data.py` remains plain, portable Python data.
"""

import sys
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore

# Allow running as `python -m scripts.seed_database` from the backend/ root.
sys.path.append(str(Path(__file__).resolve().parent.parent))

from config.settings import get_settings  # noqa: E402
from core.logging import configure_logging, get_logger  # noqa: E402
from scripts.mock_data import CONSTITUENCY, SIGNALS, SYSTEM_CONFIG, WARDS  # noqa: E402

configure_logging()
logger = get_logger(__name__)


def _initialize_firebase() -> firestore.Client:
    """Initialize Firebase Admin SDK (if not already) and return a Firestore client."""
    settings = get_settings()

    if not firebase_admin._apps:  # pylint: disable=protected-access
        cred = credentials.Certificate(settings.google_application_credentials)
        firebase_admin.initialize_app(cred, options={"projectId": settings.firebase_project_id})

    return firestore.client()


def _to_geopoint(coords: dict) -> firestore.GeoPoint:
    """Convert a {latitude, longitude} dict into a Firestore GeoPoint."""
    return firestore.GeoPoint(coords["latitude"], coords["longitude"])


def seed_system_config(db: firestore.Client) -> None:
    """Write the system_config/sys_01 document."""
    doc_ref = db.collection("system_config").document(SYSTEM_CONFIG["id"])
    doc_ref.set(SYSTEM_CONFIG)
    logger.info("Seeded system_config/%s", SYSTEM_CONFIG["id"])


def seed_constituency(db: firestore.Client) -> None:
    """Write the constituencies/{id} document, including its geopoint center."""
    payload = dict(CONSTITUENCY)
    payload["center"] = _to_geopoint(payload["center"])

    doc_ref = db.collection("constituencies").document(CONSTITUENCY["id"])
    doc_ref.set(payload)
    logger.info("Seeded constituencies/%s", CONSTITUENCY["id"])


def seed_wards(db: firestore.Client) -> None:
    """Write each ward document into constituencies/{id}/wards."""
    wards_ref = db.collection("constituencies").document(CONSTITUENCY["id"]).collection("wards")
    for ward in WARDS:
        wards_ref.document(ward["id"]).set(ward)
    logger.info("Seeded %d ward documents.", len(WARDS))


def seed_signals(db: firestore.Client) -> None:
    """Write each signal document into constituencies/{id}/signals, with timestamp."""
    signals_ref = db.collection("constituencies").document(CONSTITUENCY["id"]).collection("signals")
    for signal in SIGNALS:
        payload = dict(signal)
        payload["coords"] = _to_geopoint(payload["coords"])
        payload["timestamp"] = firestore.SERVER_TIMESTAMP
        signals_ref.document(signal["id"]).set(payload)
    logger.info("Seeded %d signal documents.", len(SIGNALS))


def run() -> None:
    """Execute the full seeding sequence."""
    db = _initialize_firebase()
    logger.info("Beginning Firestore seed for constituency '%s'.", CONSTITUENCY["id"])

    seed_system_config(db)
    seed_constituency(db)
    seed_wards(db)
    seed_signals(db)

    logger.info("Firestore seed completed successfully.")


if __name__ == "__main__":
    run()
