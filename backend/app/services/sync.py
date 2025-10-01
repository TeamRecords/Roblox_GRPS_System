from __future__ import annotations

import logging
from typing import Dict, Optional, Tuple

import httpx
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..models import Player
from ..schemas import PlayerSnapshotPayload
from .ingestion import IngestionService
from .roblox_client import RobloxClient

logger = logging.getLogger(__name__)


class RobloxSyncService:
    """Synchronise Roblox DataStore snapshots into the local database."""

    def __init__(
        self,
        session: AsyncSession,
        *,
        client: Optional[RobloxClient] = None,
    ) -> None:
        self.session = session
        self.client = client or RobloxClient()
        self.settings = get_settings()
        self.ingestion = IngestionService(session)

    async def sync_leaderboard(
        self,
        *,
        limit: int = 100,
        cursor: Optional[str] = None,
    ) -> Tuple[int, int, Optional[str]]:
        universe_id = self.settings.default_universe_id
        if universe_id is None:
            raise ValueError("ROBLOX_UNIVERSE_ID is not configured")

        datastore_name = self.settings.datastore_name
        scope = self.settings.datastore_scope
        prefix = self.settings.datastore_key_prefix

        listing = await self.client.list_datastore_entries(
            universe_id=universe_id,
            datastore_name=datastore_name,
            scope=scope,
            prefix=prefix,
            limit=limit,
            cursor=cursor,
        )

        entries = listing.get("entries", [])
        next_cursor = listing.get("nextPageCursor") or listing.get("nextCursor")

        created = 0
        updated = 0

        for entry in entries:
            key = entry.get("entryKey") or entry.get("key")
            if not key:
                logger.warning("Skipping Roblox datastore entry without key: %s", entry)
                continue

            user_id = self._extract_user_id(key, prefix)
            if user_id is None:
                logger.warning("Unable to extract userId from key '%s'", key)
                continue

            try:
                payload = await self.client.read_datastore_entry(
                    universe_id=universe_id,
                    datastore_name=datastore_name,
                    key=key,
                    scope=scope,
                )
            except httpx.HTTPStatusError as error:  # pragma: no cover - network errors
                logger.error("Failed to fetch datastore entry %s: %s", key, error)
                continue

            if not isinstance(payload, dict):
                logger.warning("Datastore entry %s returned non-JSON payload", key)
                continue

            snapshot_dict = self._build_snapshot(payload, user_id)
            try:
                snapshot = PlayerSnapshotPayload.model_validate(snapshot_dict)
            except ValidationError as error:
                logger.error("Invalid snapshot payload for user %s: %s", user_id, error)
                continue

            existing = await self.session.get(Player, user_id)
            await self.ingestion.ingest(snapshot, experience_key=payload.get("experienceKey"))

            if existing:
                updated += 1
            else:
                created += 1

        await self.session.commit()
        return updated, created, next_cursor

    @staticmethod
    def _extract_user_id(key: str, prefix: Optional[str]) -> Optional[int]:
        raw = key
        if prefix and raw.startswith(prefix):
            raw = raw[len(prefix) :]

        try:
            return int(raw)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _build_snapshot(payload: Dict[str, object], user_id: int) -> Dict[str, object]:
        rank_points = payload.get("rankPoints") or payload.get("points") or 0
        kos = payload.get("kos") or payload.get("kills") or 0
        wos = payload.get("wos") or payload.get("deaths") or 0

        return {
            "userId": payload.get("userId") or user_id,
            "username": payload.get("username") or payload.get("name") or f"User {user_id}",
            "displayName": payload.get("displayName"),
            "rank": payload.get("rank") or payload.get("role"),
            "rankPoints": int(rank_points) if rank_points is not None else 0,
            "kos": int(kos) if kos is not None else 0,
            "wos": int(wos) if wos is not None else 0,
            "warnings": payload.get("warnings") or payload.get("warns") or 0,
            "recommendations": payload.get("recommendations") or payload.get("recs") or 0,
            "punishmentStatus": payload.get("punishmentStatus"),
            "punishmentExpiresAt": payload.get("punishmentExpiresAt"),
            "experience": payload.get("experience"),
            "metadata": payload.get("metadata") or {},
            "groupId": payload.get("groupId"),
        }


__all__ = ["RobloxSyncService"]

