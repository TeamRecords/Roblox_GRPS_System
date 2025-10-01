from __future__ import annotations

import secrets
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..models import Player
from ..schemas import AutomationDecision
from .rank_policy import RankPolicy, get_rank_policy
from .roblox_client import RobloxClient


class AutomationService:
    """Determines and optionally executes GRPS automation decisions."""

    def __init__(
        self,
        session: AsyncSession,
        policy: Optional[RankPolicy] = None,
        roblox_client: Optional[RobloxClient] = None,
    ):
        self.session = session
        self.policy = policy or get_rank_policy()
        self.roblox = roblox_client or RobloxClient()

    async def evaluate(self, player: Player, *, apply: bool = False, reason: Optional[str] = None, actor_user_id: Optional[int] = None) -> AutomationDecision:
        action, target_rank, message = self._resolve_action(player)
        decision = AutomationDecision(
            action=action,
            target_rank=target_rank,
            reason=reason or message,
            apply=apply,
            request_id=secrets.token_hex(8),
        )
        if apply and decision.action != "NONE":
            await self._apply_decision(player, decision, actor_user_id=actor_user_id)
        return decision

    def _resolve_action(self, player: Player) -> tuple[str, Optional[str], str]:
        punishments = player.punishment_status or ""
        if player.warnings >= 7 or punishments == "Punishment_Severe":
            return "BAN", None, "Warnings exceed severe threshold"
        if player.warnings >= 4 or punishments == "Trial_Punishment":
            if player.rank != "Suspended":
                return "SUSPEND", "Suspended", "Trial punishment in effect"
            return "NONE", None, "Player already suspended"

        current_rank = self.policy.get_rank(player.rank) or self.policy.rank_for_points(player.rank_points)
        if current_rank:
            next_rank = self.policy.next_rank_by_name(current_rank.name)
            previous_rank = self.policy.previous_rank_by_name(current_rank.name)
            if next_rank and player.rank_points >= next_rank.min_points:
                if self.policy.is_privileged(current_rank.name) or next_rank.privileged:
                    return "PROMOTE", next_rank.name, "Eligible for promotion"
            if previous_rank and player.rank_points < current_rank.min_points:
                return "DEMOTE", previous_rank.name, "Rank points below threshold"

        return "NONE", None, "No action required"

    async def _apply_decision(self, player: Player, decision: AutomationDecision, *, actor_user_id: Optional[int] = None) -> None:
        if decision.action == "SUSPEND":
            await self._transition_rank(player, "Suspended")
            player.punishment_status = "Trial_Punishment"
            player.punishment_expires_at = datetime.utcnow() + timedelta(days=14)
        elif decision.action == "PROMOTE" and decision.target_rank:
            await self._transition_rank(player, decision.target_rank)
        elif decision.action == "DEMOTE" and decision.target_rank:
            await self._transition_rank(player, decision.target_rank)
        elif decision.action == "BAN":
            player.punishment_status = "Punishment_Severe"
        player.last_synced_at = datetime.utcnow()
        await self.session.flush()

    async def _transition_rank(self, player: Player, rank_name: str) -> None:
        role = self.policy.get_rank(rank_name)
        if not role:
            raise ValueError(f"Unknown rank {rank_name}")
        if role.role_id is None:
            raise ValueError(f"Rank {rank_name} missing roleId in configuration")
        await self.roblox.update_group_role(player.user_id, role.role_id)
        player.previous_rank = player.rank
        player.rank = rank_name


__all__ = ["AutomationService"]
