from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Player, PlayerSnapshot
from ..schemas import PlayerSnapshotPayload
from .calculations import CalculationService


class IngestionService:
    """Persists Roblox snapshots and enriches them for downstream automation."""

    def __init__(self, session: AsyncSession, calculator: Optional[CalculationService] = None):
        self.session = session
        self.calculator = calculator or CalculationService()

    async def ingest(self, snapshot: PlayerSnapshotPayload, *, experience_key: Optional[str] = None, actor_user_id: Optional[int] = None) -> Player:
        player = await self._get_or_create_player(snapshot.user_id)
        self.calculator.apply_snapshot(player, snapshot)
        player.last_synced_at = datetime.utcnow()

        self.session.add(
            PlayerSnapshot(
                user_id=snapshot.user_id,
                payload=snapshot.model_dump(mode="json"),
                experience_key=experience_key,
                actor_user_id=actor_user_id,
            )
        )
        await self.session.flush()
        return player

    async def _get_or_create_player(self, user_id: int) -> Player:
        result = await self.session.execute(select(Player).where(Player.user_id == user_id))
        player = result.scalar_one_or_none()
        if player is None:
            player = Player(user_id=user_id, username="", rank="Initiate", rank_points=0, kos=0, wos=0)
            self.session.add(player)
            await self.session.flush()
        return player


__all__ = ["IngestionService"]
