from __future__ import annotations

from typing import Dict, List, Optional

from sqlalchemy import Select, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import Player
from .calculations import CalculationService


class LeaderboardService:
    """Read-only aggregation helpers for public leaderboard endpoints."""

    def __init__(
        self,
        session: AsyncSession,
        *,
        calculator: Optional[CalculationService] = None,
    ) -> None:
        self.session = session
        self.calculator = calculator or CalculationService()

    async def fetch_top_players(self, limit: int = 25) -> List[Dict[str, object]]:
        statement: Select[tuple[Player]] = (
            select(Player)
            .order_by(desc(Player.rank_points), desc(Player.kos))
            .limit(limit)
        )
        result = await self.session.execute(statement)
        players = result.scalars().all()
        payload: List[Dict[str, object]] = []
        for player in players:
            serialised = self.calculator.serialize_player(player)
            payload.append(
                {
                    "userId": serialised["userId"],
                    "username": serialised["username"],
                    "rank": serialised["rank"],
                    "points": serialised["rankPoints"],
                    "kos": serialised["kos"],
                    "wos": serialised["wos"],
                    "lastSyncedAt": serialised.get("lastSyncedAt"),
                }
            )
        return payload

    async def fetch_record_holders(self, limit: int = 5) -> Dict[str, List[Dict[str, object]]]:
        kos_statement: Select[tuple[Player]] = select(Player).order_by(desc(Player.kos)).limit(limit)
        wos_statement: Select[tuple[Player]] = select(Player).order_by(desc(Player.wos)).limit(limit)

        kos_result = await self.session.execute(kos_statement)
        wos_result = await self.session.execute(wos_statement)

        def _to_record(player: Player, field: str) -> Dict[str, object]:
            value = getattr(player, field)
            return {
                "userId": int(player.user_id),
                "username": player.username,
                field: int(value) if value is not None else None,
            }

        return {
            "kos": [_to_record(player, "kos") for player in kos_result.scalars().all()],
            "wos": [_to_record(player, "wos") for player in wos_result.scalars().all()],
        }


__all__ = ["LeaderboardService"]
