"""
Incoming Pydantic validation payload structures (EDD V2, Document 03).

These define and validate the exact request contract for
`POST /api/v1/mission/generate`.
"""

from pydantic import BaseModel, Field, field_validator


class LatLng(BaseModel):
    """A single geographic coordinate as used in the map_bounds payload."""

    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)


class MapBounds(BaseModel):
    """North-east / south-west bounding box of the client's current map viewport."""

    ne: LatLng
    sw: LatLng

    @field_validator("sw")
    @classmethod
    def _sw_must_be_south_west_of_ne(cls, sw: LatLng, info) -> LatLng:
        ne = info.data.get("ne")
        if ne is not None and (sw.lat > ne.lat or sw.lng > ne.lng):
            raise ValueError(
                "map_bounds.sw must be south-west of map_bounds.ne "
                "(sw.lat <= ne.lat and sw.lng <= ne.lng)."
            )
        return sw


class MissionGenerationRequest(BaseModel):
    """Request body for POST /api/v1/mission/generate."""

    constituency_id: str = Field(min_length=1, max_length=128)
    command: str = Field(min_length=3, max_length=500)
    map_bounds: MapBounds
