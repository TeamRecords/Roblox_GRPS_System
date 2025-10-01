from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..db import get_session
from ..models import Player
from ..schemas import AutomationDecisionResponse, AutomationRequest, PlayerWithContext
from ..services.automation import AutomationService
from ..services.calculations import CalculationService

router = APIRouter(prefix="/automation", tags=["automation"])


@router.post("/decisions", response_model=AutomationDecisionResponse)
async def request_decision(request: AutomationRequest, session: AsyncSession = Depends(get_session)) -> AutomationDecisionResponse:
    result = await session.execute(select(Player).where(Player.user_id == request.user_id))
    player = result.scalar_one_or_none()
    if not player:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="player not found")
    automation = AutomationService(session)
    decision = await automation.evaluate(
        player,
        apply=request.apply,
        reason=request.reason or "manual automation request",
        actor_user_id=request.actor_user_id,
    )
    calculator = CalculationService()
    payload = calculator.serialize_player(player)
    return AutomationDecisionResponse(decision=decision, player=PlayerWithContext(**payload))


__all__ = ["router"]
