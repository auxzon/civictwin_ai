"""
Low-level Firestore repository abstraction (EDD V2, Document 01).

This is the *only* module in the backend that talks to Firestore directly.
Services and controllers depend on this abstraction, never on
`google.cloud.firestore` directly — this keeps the persistence layer
swappable and testable via mocking.
"""

from datetime import UTC, datetime, timedelta

from firebase_admin import firestore as firebase_firestore
from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from config.settings import get_settings
from core.logging import get_logger
from domain.models.firestore import Constituency, GeoPointModel, Signal, Ward
from domain.schemas.requests import MapBounds

logger = get_logger(__name__)

_AI_CACHE_COLLECTION = "ai_cache"
_CONSTITUENCIES_COLLECTION = "constituencies"
_WARDS_SUBCOLLECTION = "wards"
_SIGNALS_SUBCOLLECTION = "signals"
_MISSION_HISTORY_COLLECTION = "mission_history"


def _geopoint_to_model(gp: firestore.GeoPoint) -> GeoPointModel:
    return GeoPointModel(latitude=gp.latitude, longitude=gp.longitude)


class FirestoreRepository:
    """Async-facing repository wrapping the (synchronous) Firestore client."""

    def __init__(self) -> None:
        self._settings = get_settings()
        # Uses firebase_admin's Firestore binding rather than constructing
        # google.cloud.firestore.Client() directly. The latter resolves
        # credentials via google.auth.default() (Application Default
        # Credentials), which reads GOOGLE_APPLICATION_CREDENTIALS from the
        # real OS environment — but pydantic-settings loads .env values
        # into the Settings model without exporting them to os.environ, so
        # a value that only exists in .env would silently fail ADC
        # resolution. firebase_admin.firestore.client() instead reuses the
        # credentials already loaded explicitly in main.py's
        # _initialize_firebase_admin(), so it works regardless of ambient
        # OS environment state.
        self._client = firebase_firestore.client()

    async def check_ai_cache(self, command_hash: str) -> dict | None:
        """Return the cached MissionResponse payload if a non-expired entry exists."""
        doc = self._client.collection(_AI_CACHE_COLLECTION).document(command_hash).get()
        if not doc.exists:
            return None

        data = doc.to_dict()
        ttl_expiration = data.get("ttl_expiration")
        if ttl_expiration is not None and ttl_expiration < datetime.now(UTC):
            logger.info("ai_cache entry '%s' expired; ignoring.", command_hash)
            return None

        return data.get("response_payload")

    async def write_ai_cache(self, command_hash: str, command: str, response_payload: dict) -> None:
        """Persist a MissionResponse payload with a 2-hour sliding TTL."""
        ttl_hours = self._settings.ai_cache_ttl_hours
        now = datetime.now(UTC)
        self._client.collection(_AI_CACHE_COLLECTION).document(command_hash).set(
            {
                "id": command_hash,
                "command": command,
                "response_payload": response_payload,
                "timestamp": now,
                "ttl_expiration": now + timedelta(hours=ttl_hours),
            }
        )

    async def get_constituency(self, constituency_id: str) -> Constituency | None:
        """Fetch a single constituency document, or None if it doesn't exist."""
        doc = self._client.collection(_CONSTITUENCIES_COLLECTION).document(constituency_id).get()
        if not doc.exists:
            return None

        data = doc.to_dict()
        return Constituency(
            id=doc.id,
            name=data["name"],
            state=data["state"],
            total_budget_allocated=data.get("total_budget_allocated", 50_000_000),
            budget_utilized=data.get("budget_utilized", 0),
            center=_geopoint_to_model(data["center"]),
        )

    async def get_wards(self, constituency_id: str) -> list[Ward]:
        """Fetch every ward under a constituency."""
        docs = (
            self._client.collection(_CONSTITUENCIES_COLLECTION)
            .document(constituency_id)
            .collection(_WARDS_SUBCOLLECTION)
            .stream()
        )
        wards: list[Ward] = []
        for doc in docs:
            data = doc.to_dict()
            wards.append(
                Ward(
                    id=doc.id,
                    ward_number=data["ward_number"],
                    name=data["name"],
                    population=data["population"],
                    critical_infrastructure_count=data["critical_infrastructure_count"],
                    polygon_coordinates=[
                        GeoPointModel(latitude=p["latitude"], longitude=p["longitude"])
                        for p in data.get("polygon_coordinates", [])
                    ],
                )
            )
        return wards

    async def get_signals_within_bounds(
        self, constituency_id: str, map_bounds: MapBounds
    ) -> list[Signal]:
        """
        Fetch open signals for a constituency within the client's map viewport.

        Firestore has no native geo-bounding-box query without a geohash
        index (not specified in the frozen schema), so the bounding-box
        filter is applied in-memory after fetching all open signals for
        the constituency. This is acceptable at the mock-data scale
        (dozens of signals per constituency) but should be revisited if
        the dataset grows significantly.
        """
        docs = (
            self._client.collection(_CONSTITUENCIES_COLLECTION)
            .document(constituency_id)
            .collection(_SIGNALS_SUBCOLLECTION)
            .where(filter=FieldFilter("status", "==", "Open"))
            .stream()
        )

        signals: list[Signal] = []
        for doc in docs:
            data = doc.to_dict()
            coords = _geopoint_to_model(data["coords"])
            if not self._within_bounds(coords, map_bounds):
                continue
            signals.append(
                Signal(
                    id=doc.id,
                    ward_id=data["ward_id"],
                    category=data["category"],
                    severity=data["severity"],
                    coords=coords,
                    description=data["description"],
                    status=data["status"],
                    timestamp=data["timestamp"],
                )
            )
        return signals

    @staticmethod
    def _within_bounds(point: GeoPointModel, bounds: MapBounds) -> bool:
        return (
            bounds.sw.lat <= point.latitude <= bounds.ne.lat
            and bounds.sw.lng <= point.longitude <= bounds.ne.lng
        )

    async def save_mission_history(
        self,
        user_id: str,
        constituency_id: str,
        command: str,
        response_payload: dict,
    ) -> None:
        """Persist a generated mission response to mission_history."""
        self._client.collection(_MISSION_HISTORY_COLLECTION).add(
            {
                "user_id": user_id,
                "constituency_id": constituency_id,
                "command": command,
                "selected_plan_payload": response_payload,
                "is_implemented": False,
                "created_at": datetime.now(UTC),
            }
        )

    async def get_mission_history(
        self, user_id: str, constituency_id: str, limit: int = 20
    ) -> list[dict]:
        """
        Fetch a user's mission history for a constituency, most recent first.

        Uses the composite index on (constituency_id ASC, created_at DESC)
        already defined in firebase/firestore.indexes.json. Filtered to
        `user_id` in-memory after the indexed query, since the frozen
        index does not include user_id as a filter field and adding one
        would require amending firestore.indexes.json (a frozen document)
        — acceptable at mock-data scale, flagged the same way as the
        signals bounding-box filter above.
        """
        docs = (
            self._client.collection(_MISSION_HISTORY_COLLECTION)
            .where(filter=FieldFilter("constituency_id", "==", constituency_id))
            .order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit * 5)  # over-fetch before in-memory user_id filtering
            .stream()
        )

        results: list[dict] = []
        for doc in docs:
            data = doc.to_dict()
            if data.get("user_id") != user_id:
                continue
            results.append(
                {
                    "id": doc.id,
                    "command": data["command"],
                    "selected_plan_payload": data["selected_plan_payload"],
                    "is_implemented": data.get("is_implemented", False),
                    "created_at": data["created_at"].isoformat(),
                }
            )
            if len(results) >= limit:
                break

        return results

    async def get_all_signals(self, constituency_id: str) -> list[Signal]:
        """Fetch all open signals for a constituency."""
        docs = (
            self._client.collection(_CONSTITUENCIES_COLLECTION)
            .document(constituency_id)
            .collection(_SIGNALS_SUBCOLLECTION)
            .where(filter=FieldFilter("status", "==", "Open"))
            .stream()
        )

        signals: list[Signal] = []
        for doc in docs:
            data = doc.to_dict()
            coords = _geopoint_to_model(data["coords"])
            signals.append(
                Signal(
                    id=doc.id,
                    ward_id=data["ward_id"],
                    category=data["category"],
                    severity=data["severity"],
                    coords=coords,
                    description=data["description"],
                    status=data["status"],
                    timestamp=data["timestamp"],
                )
            )
        return signals

    async def update_budget_utilized(self, constituency_id: str, additional_amount: int) -> None:
        """Increment a constituency's budget_utilized (called once a plan is implemented)."""
        doc_ref = self._client.collection(_CONSTITUENCIES_COLLECTION).document(constituency_id)
        doc_ref.update({"budget_utilized": firestore.Increment(additional_amount)})
