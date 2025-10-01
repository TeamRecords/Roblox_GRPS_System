from __future__ import annotations

from typing import Optional

from ..models import Player
from ..schemas import PlayerSnapshotPayload
from .rank_policy import RankPolicy, get_rank_policy


class CalculationService:
    """Derives contextual information from raw player snapshots."""

    def __init__(self, policy: Optional[RankPolicy] = None):
        self.policy = policy or get_rank_policy()

    def build_player_record(self, snapshot: PlayerSnapshotPayload) -> dict:
        resolved_rank = self.policy.rank_for_points(snapshot.rank_points)
        rank_name = snapshot.rank or (resolved_rank.name if resolved_rank else "Initiate")
        rank_descriptor = self.policy.get_rank(rank_name) or resolved_rank
        next_rank = self.policy.next_rank_by_name(rank_descriptor.name) if rank_descriptor else self.policy.next_rank(snapshot.rank_points)
        previous_rank = self.policy.previous_rank_by_name(rank_descriptor.name) if rank_descriptor else self.policy.previous_rank(snapshot.rank_points)
        privileged = self.policy.is_privileged(rank_name)
        decisions_blocked = snapshot.punishment_status == "Trial_Punishment"

        return {
            "user_id": snapshot.user_id,
            "username": snapshot.username,
            "display_name": snapshot.display_name,
            "rank": rank_name,
            "rank_points": snapshot.rank_points,
            "kos": snapshot.kos,
            "wos": snapshot.wos,
            "warnings": snapshot.warnings,
            "recommendations": snapshot.recommendations,
            "punishment_status": snapshot.punishment_status,
            "punishment_expires_at": snapshot.punishment_expires_at,
            "privileged": privileged,
            "previous_rank": previous_rank.name if previous_rank else None,
            "next_rank": next_rank.name if next_rank else None,
            "next_rank_required_points": next_rank.min_points if next_rank else None,
            "previous_rank_required_points": previous_rank.min_points if previous_rank else None,
            "decisions_blocked": decisions_blocked,
        }

    def apply_snapshot(self, player: Player, snapshot: PlayerSnapshotPayload) -> Player:
        payload = self.build_player_record(snapshot)
        player.username = payload["username"]
        player.display_name = payload["display_name"]
        player.rank = payload["rank"]
        player.rank_points = payload["rank_points"]
        player.kos = payload["kos"]
        player.wos = payload["wos"]
        player.warnings = payload["warnings"]
        player.recommendations = payload["recommendations"]
        player.punishment_status = payload["punishment_status"]
        player.punishment_expires_at = payload["punishment_expires_at"]
        player.privileged = bool(payload["privileged"])
        player.previous_rank = payload["previous_rank"]
        player.next_rank = payload["next_rank"]
        player.metadata_payload = {"decisionsBlocked": payload["decisions_blocked"]}
        return player

    def serialize_player(self, player: Player) -> dict:
        descriptor = self.policy.get_rank(player.rank)
        next_rank = self.policy.next_rank_by_name(player.rank) if descriptor else None
        previous_rank = self.policy.previous_rank_by_name(player.rank) if descriptor else None
        decisions_blocked = bool(player.metadata_payload and player.metadata_payload.get("decisionsBlocked")) or (
            player.punishment_status == "Trial_Punishment"
        )

        return {
            "userId": player.user_id,
            "username": player.username,
            "displayName": player.display_name,
            "rank": player.rank,
            "previousRank": player.previous_rank,
            "nextRank": player.next_rank,
            "rankPoints": player.rank_points,
            "kos": player.kos,
            "wos": player.wos,
            "warnings": player.warnings,
            "recommendations": player.recommendations,
            "privileged": bool(player.privileged),
            "punishmentStatus": player.punishment_status,
            "punishmentExpiresAt": player.punishment_expires_at,
            "createdAt": player.created_at,
            "lastSyncedAt": player.last_synced_at,
            "nextRankRequiredPoints": next_rank.min_points if next_rank else None,
            "previousRankRequiredPoints": previous_rank.min_points if previous_rank else None,
            "decisionsBlocked": decisions_blocked,
            "metadata": player.metadata_payload or {},
        }


__all__ = ["CalculationService"]
