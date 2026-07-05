"""Version 1 aggregated routing registry (EDD V2, Document 01)."""

from fastapi import APIRouter

from api.v1.controllers import mission

api_router = APIRouter()
api_router.include_router(mission.router, tags=["Mission"])
