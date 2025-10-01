from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..models import Player
from ..schemas import PlayerWithContext
from ..services.calculations import CalculationService

router = APIRouter(prefix="/players", tags=["players"])


@router.get("/{user_id}", response_model=PlayerWithContext)
async def get_player(user_id: int, session: AsyncSession = Depends(get_session)) -> PlayerWithContext:
    result = await session.execute(select(Player).where(Player.user_id == user_id))
    player = result.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="player not found")
    calculator = CalculationService()
    payload = calculator.serialize_player(player)
    return PlayerWithContext(**payload)


__all__ = ["router"]
