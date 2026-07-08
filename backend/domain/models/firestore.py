"""
Local structures mirroring Firestore documents (EDD V2, Document 02).

These are the backend's typed representation of what's actually stored in
Firestore. They are intentionally separate from `domain/schemas/` (the
API request/response DTOs) — a Firestore document shape and an API
contract shape are allowed to diverge, and collapsing them into one model
would couple the database schema to the wire format.
"""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class GeoPointModel(BaseModel):
    """Mirrors a Firestore GeoPoint (latitude/longitude pair)."""

    latitude: float
    longitude: float


class ImpactWeights(BaseModel):
    """Scoring weights from system_config/sys_01 (Document 04 formula)."""

    population: float = 0.30
    severity: float = 0.25
    efficiency: float = 0.20
    infrastructure: float = 0.15
    signals: float = 0.10


class SystemConfig(BaseModel):
    """system_config/{id}"""

    id: str
    bhashini_endpoint: str
    gemini_active_model: str
    impact_weights: ImpactWeights


class User(BaseModel):
    """users/{uid}"""

    uid: str
    name: str
    role: Literal["MP", "PLANNER", "ADMIN"]
    constituency_id: str
    created_at: datetime


class Constituency(BaseModel):
    """constituencies/{id}"""

    id: str
    name: str
    state: str
    total_budget_allocated: int = Field(default=50_000_000)
    budget_utilized: int = 0
    center: GeoPointModel

    @property
    def remaining_budget(self) -> int:
        return self.total_budget_allocated - self.budget_utilized


class Ward(BaseModel):
    """constituencies/{id}/wards/{ward_id}"""

    id: str
    ward_number: str
    name: str
    population: int
    critical_infrastructure_count: int
    polygon_coordinates: list[GeoPointModel]


class Signal(BaseModel):
    """constituencies/{id}/signals/{signal_id}"""

    id: str
    ward_id: str
    category: str
    severity: int = Field(ge=1, le=10)
    coords: GeoPointModel
    description: str
    status: str
    timestamp: datetime


class AICacheEntry(BaseModel):
    """ai_cache/{sha256_hash_id}"""

    id: str
    command: str
    response_payload: dict
    timestamp: datetime
    ttl_expiration: datetime


class MissionHistoryEntry(BaseModel):
    """mission_history/{id}"""

    id: str | None = None
    user_id: str
    constituency_id: str
    command: str
    selected_plan_payload: dict
    is_implemented: bool = False
    created_at: datetime
