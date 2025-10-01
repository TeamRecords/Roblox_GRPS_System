from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Literal, Optional

from pydantic import BaseModel, Field, validator

AutomationAction = Literal["PROMOTE", "DEMOTE", "SUSPEND", "BAN", "NONE"]


class ExperienceContext(BaseModel):
    universe_id: Optional[int] = Field(None, alias="universeId")
    place_id: Optional[int] = Field(None, alias="placeId")
    server: Optional[str] = None
    key: Optional[str] = Field(None, alias="experienceKey")


class PlayerSnapshotPayload(BaseModel):
    user_id: int = Field(..., alias="userId")
    username: str
    display_name: Optional[str] = Field(None, alias="displayName")
    rank: Optional[str] = None
    rank_points: int = Field(..., alias="rankPoints", ge=0)
    kos: int = Field(..., ge=0)
    wos: int = Field(..., ge=0)
    warnings: int = Field(0, ge=0)
    recommendations: int = Field(0, ge=0)
    punishment_status: Optional[str] = Field(None, alias="punishmentStatus")
    punishment_expires_at: Optional[datetime] = Field(None, alias="punishmentExpiresAt")
    experience: Optional[ExperienceContext] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    group_id: Optional[int] = Field(None, alias="groupId")

    class Config:
        populate_by_name = True

    @validator("rank")
    def normalise_rank(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        return value.strip()


class PlayerRecord(BaseModel):
    user_id: int = Field(..., alias="userId")
    username: str
    display_name: Optional[str] = Field(None, alias="displayName")
    rank: str
    previous_rank: Optional[str] = Field(None, alias="previousRank")
    next_rank: Optional[str] = Field(None, alias="nextRank")
    rank_points: int = Field(..., alias="rankPoints")
    kos: int
    wos: int
    warnings: int
    recommendations: int
    privileged: bool
    punishment_status: Optional[str] = Field(None, alias="punishmentStatus")
    punishment_expires_at: Optional[datetime] = Field(None, alias="punishmentExpiresAt")
    last_synced_at: datetime = Field(..., alias="lastSyncedAt")


class PlayerWithContext(PlayerRecord):
    next_rank_required_points: Optional[int] = Field(None, alias="nextRankRequiredPoints")
    previous_rank_required_points: Optional[int] = Field(None, alias="previousRankRequiredPoints")
    decisions_blocked: bool = Field(False, alias="decisionsBlocked")


class AutomationDecision(BaseModel):
    action: AutomationAction
    reason: str
    target_rank: Optional[str] = Field(None, alias="targetRank")
    apply: bool = False
    request_id: str = Field(..., alias="requestId")


class AutomationDecisionResponse(BaseModel):
    decision: AutomationDecision
    player: PlayerWithContext


class SnapshotIngestResponse(BaseModel):
    player: PlayerWithContext
    decision: Optional[AutomationDecision] = None


class AutomationRequest(BaseModel):
    user_id: int = Field(..., alias="userId")
    actor_user_id: Optional[int] = Field(None, alias="actorUserId")
    apply: bool = False
    reason: Optional[str] = None


class HealthStatus(BaseModel):
    status: Literal["ok", "degraded", "down"]
    timestamp: datetime


__all__ = [
    "AutomationAction",
    "AutomationDecision",
    "AutomationDecisionResponse",
    "AutomationRequest",
    "ExperienceContext",
    "HealthStatus",
    "PlayerRecord",
    "PlayerSnapshotPayload",
    "PlayerWithContext",
    "SnapshotIngestResponse",
]
