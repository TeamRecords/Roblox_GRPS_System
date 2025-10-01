from __future__ import annotations

import hashlib
import hmac
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import get_settings
from ..db import get_session
from ..schemas import RobloxSyncRequest, RobloxSyncResponse
from ..services.sync import RobloxSyncService

router = APIRouter(prefix="/sync", tags=["sync"])


def _verify_signature(signature: Optional[str], body: bytes) -> None:
    settings = get_settings()
    secret = settings.automation_signature_secret
    if not secret:
        return

    if not signature:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing signature")

    digest = hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(digest, signature):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid signature")


@router.post("/roblox", response_model=RobloxSyncResponse)
async def sync_roblox(
    request: Request,
    signature: Optional[str] = Header(default=None, alias="x-grps-signature"),
    session: AsyncSession = Depends(get_session),
) -> RobloxSyncResponse:
    body = await request.body()
    _verify_signature(signature, body)

    try:
        payload = RobloxSyncRequest.model_validate_json(body)
    except ValidationError as error:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=error.errors()) from error

    if payload.activity != "leaderboard":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="unsupported activity")

    service = RobloxSyncService(session)
    try:
        updated, created, next_cursor = await service.sync_leaderboard(limit=payload.limit, cursor=payload.cursor)
    except ValueError as error:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(error)) from error

    return RobloxSyncResponse(updated=updated, created=created, next_cursor=next_cursor)


__all__ = ["router"]

