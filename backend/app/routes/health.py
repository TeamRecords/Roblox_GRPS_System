from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter

from ..schemas import HealthStatus

router = APIRouter(prefix="/health", tags=["health"])


@router.get("/live", response_model=HealthStatus)
async def live() -> HealthStatus:
    return HealthStatus(status="ok", timestamp=datetime.utcnow())


__all__ = ["router"]
