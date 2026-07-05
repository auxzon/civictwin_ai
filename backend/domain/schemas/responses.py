"""
Outbound DTO schemas mapping the rigid client contract (EDD V2, Documents
03 and 04).

`MissionBrief` mirrors `AIMissionBrief` (the schema Gemini is constrained
to produce — defined in `services/ai_pipeline.py`) with one critical
difference: `impact_score` here is always the value computed by the
deterministic `impact_engine`, never a value trusted from the LLM. See
the "Deterministic Reasoning" decision in DECISIONS.md.
"""

from typing import Literal

from pydantic import BaseModel, Field


class MissionBrief(BaseModel):
    """A single recommended plan, as returned to the Flutter client."""

    mission_id: str
    mission: str
    priority: Literal["HIGH", "MEDIUM", "LOW"]
    budget: int = Field(ge=0)
    impact_score: int = Field(ge=0, le=100)
    confidence: int = Field(ge=0, le=100)
    confidence_explanation: str
    beneficiaries: int = Field(ge=0)
    estimated_completion: str
    department: str
    evidence: list[str] = Field(max_length=3)
    risks: str
    action_items: list[str] = Field(min_length=3, max_length=3)
    success_metrics: list[str] = Field(min_length=2, max_length=2)
    timeline_decay_rate: float = Field(ge=0.01, le=0.50)
    alternative: str


class MissionResponse(BaseModel):
    """Full response body for POST /api/v1/mission/generate."""

    mission_id: str
    command_summary: str
    briefs: list[MissionBrief]


class MissionHistoryItem(BaseModel):
    """
    A single entry in a user's mission history.

    NOTE: this schema and its endpoint (GET /mission/history) are not
    part of the literal EDD V2 Document 03 API contract, which only
    specifies POST /mission/generate. They exist to fill a gap: Document
    01's "Complete Unified State Machine" explicitly requires a "History
    Mode (Fetches historical plan collections from session)" transition,
    but no read endpoint was ever specified for it, only the write side
    (mission_history collection). This is an additive fill, not a change
    to any existing frozen behavior — see DECISIONS.md.
    """

    id: str
    command: str
    selected_plan_payload: MissionResponse
    is_implemented: bool
    created_at: str


class MissionHistoryListResponse(BaseModel):
    """Response body for GET /mission/history."""

    items: list[MissionHistoryItem]
