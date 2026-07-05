"""Smoke tests for application bootstrap and the /health liveness endpoint."""

from fastapi.testclient import TestClient


def test_health_endpoint_returns_ok() -> None:
    """The app must boot successfully and /health must report status ok."""
    from main import app

    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200

    body = response.json()
    assert body["status"] == "ok"
    assert body["service"] == "CivicTwin AI Backend (Test)"
    assert body["environment"] == "development"


def test_health_endpoint_has_no_unexpected_fields() -> None:
    """Guards the response contract so Phase 2 additions are deliberate."""
    from main import app

    with TestClient(app) as client:
        response = client.get("/health")

    assert set(response.json().keys()) == {"status", "service", "environment"}
