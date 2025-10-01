from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..schemas import LeaderboardRecordsResponse, LeaderboardTopResponse
from ..services.leaderboard import LeaderboardService


router = APIRouter(prefix="/leaderboard", tags=["leaderboard"])


@router.get("/top", response_model=LeaderboardTopResponse)
async def get_top_players(
    limit: int = Query(25, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
) -> LeaderboardTopResponse:
    service = LeaderboardService(session)
    players = await service.fetch_top_players(limit)
    last_synced_at = players[0].get("lastSyncedAt") if players else None
    return LeaderboardTopResponse(players=players, lastSyncedAt=last_synced_at)


@router.get("/records", response_model=LeaderboardRecordsResponse)
async def get_record_holders(
    limit: int = Query(5, ge=1, le=50),
    session: AsyncSession = Depends(get_session),
) -> LeaderboardRecordsResponse:
    service = LeaderboardService(session)
    records = await service.fetch_record_holders(limit)
    return LeaderboardRecordsResponse(**records)


__all__ = ["router"]
