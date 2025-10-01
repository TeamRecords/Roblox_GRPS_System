from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status

from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db import get_session
from ..schemas import AutomationDecision, PlayerSnapshotPayload, SnapshotIngestResponse
from ..services.automation import AutomationService
from ..services.ingestion import IngestionService

router = APIRouter(prefix="/roblox", tags=["roblox"])


def _validate_api_key(api_key: Optional[str]) -> None:
    settings = get_settings()
    if settings.inbound_api_keys and (api_key is None or api_key not in settings.inbound_api_keys):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid api key")


@router.post("/events/player-activity", response_model=SnapshotIngestResponse)
async def ingest_player_activity(
    snapshot: PlayerSnapshotPayload,
    experience_key: Optional[str] = Header(default=None, alias="x-roblox-experience"),
    actor_user_id: Optional[int] = Header(default=None, alias="x-grps-actor"),
    api_key: Optional[str] = Header(default=None, alias="x-grps-api-key"),
    evaluate: bool = Header(default=False, alias="x-grps-evaluate"),
    apply: bool = Header(default=False, alias="x-grps-apply"),
    session: AsyncSession = Depends(get_session),
) -> SnapshotIngestResponse:
    _validate_api_key(api_key)

    ingestion = IngestionService(session)
    automation = AutomationService(session)

    player = await ingestion.ingest(snapshot, experience_key=experience_key, actor_user_id=actor_user_id)
    player_payload = ingestion.calculator.serialize_player(player)

    decision: Optional[AutomationDecision] = None
    if evaluate:
        decision = await automation.evaluate(player, apply=apply, actor_user_id=actor_user_id)
        player_payload = ingestion.calculator.serialize_player(player)

    return SnapshotIngestResponse(player=player_payload, decision=decision)


__all__ = ["router"]
