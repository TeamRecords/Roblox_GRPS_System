# GRPS Automation Service (Python FastAPI Blueprint)

This document contains the reference implementation for the Python automation layer. Copy the code blocks into actual `.py` files when materialising the service.

## 1. Service Overview
- **Framework**: FastAPI + Uvicorn (async) for a minimal, typed HTTP API.
- **Database**: PostgreSQL via SQLAlchemy 2.0 async ORM (`asyncpg`).
- **Caching / Queues**: Optional Redis for transient job state and webhook deduplication.
- **External Integrations**:
  - Roblox Open Cloud (experience metrics and DataStore reads/writes).
  - Prisma-managed Postgres (shared with the Next.js web portal).
  - Discord/Slack webhooks for audit broadcasting.
  - Cloudflare Turnstile verification for user-submitted actions.

````python
# backend/service.py
from __future__ import annotations

import hmac
import logging
from hashlib import sha256
from typing import Annotated, AsyncIterator

import httpx
from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, BaseSettings, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from . import models, roblox, webhooks

log = logging.getLogger("grps.automation")


class Settings(BaseSettings):
    database_url: str = Field(..., alias="DATABASE_URL")
    roblox_api_key: str = Field(..., alias="ROBLOX_OPEN_CLOUD_API_KEY")
    roblox_universe_id: int = Field(..., alias="ROBLOX_UNIVERSE_ID")
    roblox_datastore_name: str = Field(..., alias="ROBLOX_DATASTORE_NAME")
    roblox_datastore_scope: str = Field("global", alias="ROBLOX_DATASTORE_SCOPE")
    roblox_datastore_prefix: str | None = Field(None, alias="ROBLOX_DATASTORE_PREFIX")
    automation_signature_secret: str = Field(..., alias="AUTOMATION_SIGNATURE_SECRET")
    turnstile_secret_key: str = Field(..., alias="TURNSTILE_SECRET_KEY")
    webhook_verification_key: str = Field(..., alias="WEBHOOK_VERIFICATION_KEY")
    cors_allow_origins: list[str] = Field(default_factory=lambda: ["https://grps.example.com", "http://localhost:3000"])

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
engine = create_async_engine(settings.database_url, echo=False, future=True)
SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_session() -> AsyncIterator[AsyncSession]:
    async with SessionLocal() as session:
        yield session


def verify_signature(request: Request, body: bytes) -> None:
    signature = request.headers.get("x-grps-signature")
    if not signature:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing signature")

    digest = hmac.new(settings.automation_signature_secret.encode(), body, sha256).hexdigest()
    if not hmac.compare_digest(signature, digest):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid signature")


app = FastAPI(title="GRPS Automation API", version="2025.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allow_origins,
    allow_methods=["GET", "POST", "PUT"],
    allow_headers=["*"],
)


class SyncRequest(BaseModel):
    activity: str
    limit: int = Field(100, ge=1, le=500)
    cursor: str | None = None
    scope: str | None = None
    prefix: str | None = None


@app.get("/health/live")
async def health_live() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/sync/roblox")
async def sync_roblox(
    payload: SyncRequest,
    request: Request,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> dict[str, int]:
    body = await request.body()
    verify_signature(request, body)

    try:
        changes = await roblox.pull_activity(
            session=session,
            universe_id=settings.roblox_universe_id,
            api_key=settings.roblox_api_key,
            datastore=settings.roblox_datastore_name,
            scope=payload.scope or settings.roblox_datastore_scope,
            key_prefix=payload.prefix or settings.roblox_datastore_prefix,
            activity=payload.activity,
            limit=payload.limit,
            cursor=payload.cursor,
        )
    except httpx.HTTPError as exc:  # pragma: no cover - network failure path
        log.exception("Roblox sync failed")
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "Roblox API unavailable") from exc

    await session.commit()
    return {"updated": changes.updated, "created": changes.created}


@app.post("/webhooks/turnstile")
async def verify_turnstile(token: str) -> dict[str, bool]:
    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.post(
            "https://challenges.cloudflare.com/turnstile/v0/siteverify",
            data={"secret": settings.turnstile_secret_key, "response": token},
        )
    data = response.json()
    return {"valid": bool(data.get("success"))}


@app.get("/leaderboard")
async def get_leaderboard(
    session: Annotated[AsyncSession, Depends(get_session)],
    limit: int = 30,
) -> list[models.PlayerPublic]:
    statement = (
        select(models.Player)
        .order_by(models.Player.points.desc(), models.Player.kos.desc())
        .limit(min(limit, 100))
    )
    result = await session.execute(statement)
    return [models.PlayerPublic.from_orm(row[0]) for row in result.all()]


@app.get("/metrics/health")
async def metrics_health(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> dict[str, float]:
    total_players = await session.scalar(select(func.count(models.Player.user_id)))
    recent_updates = await session.scalar(
        select(func.count(models.Player.user_id)).where(models.Player.updated_at >= func.now() - func.make_interval(hours=1))
    )
    return {"totalPlayers": float(total_players or 0), "updatedLastHour": float(recent_updates or 0)}
````

## 2. Data Models (`backend/models.py`)
````python
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel
from sqlalchemy import BigInteger, Column, DateTime, Integer, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Player(Base):
    __tablename__ = "players"

    user_id = Column(BigInteger, primary_key=True, autoincrement=False)
    username = Column(String(64), nullable=False)
    rank = Column(String(64), nullable=True)
    points = Column(Integer, nullable=False, default=0)
    kos = Column(Integer, nullable=False, default=0)
    wos = Column(Integer, nullable=False, default=0)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=datetime.utcnow)


class SyncJob(Base):
    __tablename__ = "sync_jobs"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    activity = Column(String(32), nullable=False)
    cursor = Column(String(256), nullable=True)
    status = Column(String(16), nullable=False, default="pending")
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class PlayerPublic(BaseModel):
    user_id: int
    username: str
    rank: str | None
    points: int | None
    kos: int | None
    wos: int | None
    updated_at: datetime | None

    class Config:
        orm_mode = True
````

## 3. Roblox Client (`backend/roblox.py`)
````python
from __future__ import annotations

from dataclasses import dataclass

import json

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .models import Player, SyncJob

ROBLOX_API_BASE = "https://apis.roblox.com"


@dataclass
class SyncResult:
    updated: int
    created: int


async def pull_activity(
    session: AsyncSession,
    *,
    universe_id: int,
    api_key: str,
    datastore: str,
    scope: str = "global",
    key_prefix: str | None = None,
    activity: str,
    limit: int,
    cursor: str | None,
) -> SyncResult:
    headers = {"x-api-key": api_key}
    base_path = f"{ROBLOX_API_BASE}/datastores/v1/universes/{universe_id}/standard-datastores/{datastore}"
    list_params = {"scope": scope, "limit": limit, "cursor": cursor, "prefix": key_prefix}

    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.get(f"{base_path}/entries", params=list_params, headers=headers)
        response.raise_for_status()
        payload = response.json()

        updated = created = 0

        for entry in payload.get("data", []):
            key = entry["key"]
            detail = await client.get(
                f"{base_path}/entries/entry",
                params={"scope": scope, "key": key},
                headers=headers,
            )
            detail.raise_for_status()

            if detail.headers.get("content-type", "").startswith("application/json"):
                snapshot = detail.json()
            else:
                snapshot = json.loads(detail.text)

            user_id = int(snapshot.get("userId") or key.split(":")[-1])
            record = await session.get(Player, user_id)
            if record is None:
                record = Player(user_id=user_id, username=snapshot.get("username", "Unknown"))
                session.add(record)
                created += 1
            else:
                updated += 1

            record.rank = snapshot.get("rank", record.rank)
            record.points = snapshot.get("points", record.points)
            record.kos = snapshot.get("kos", record.kos)
            record.wos = snapshot.get("wos", record.wos)

    job = SyncJob(activity=activity, cursor=payload.get("nextPageCursor"))
    session.add(job)
    return SyncResult(updated=updated, created=created)
````

## 4. Webhook Publisher (`backend/webhooks.py`)
````python
from __future__ import annotations

import json
from typing import Iterable

import httpx


def broadcast(urls: Iterable[str], payload: dict[str, object]) -> None:
    for url in urls:
        try:
            httpx.post(url, json=payload, timeout=5)
        except httpx.HTTPError:
            continue
````

## 5. Bootstrap Script (`backend/scripts/bootstrap.py`)
````python
from __future__ import annotations

import asyncio

from ..automation import models
from ..automation.service import SessionLocal


async def seed_defaults() -> None:
    async with SessionLocal() as session:
        sample = models.Player(
            user_id=123456,
            username="LightningMarshal",
            rank="Stormmarshal",
            points=8200,
            kos=1200,
            wos=340,
        )
        session.add(sample)
        await session.commit()


if __name__ == "__main__":
    asyncio.run(seed_defaults())
````

## 6. Alembic Migration Template
````bash
alembic init migrations
alembic revision --autogenerate -m "Create players and sync_jobs"
alembic upgrade head
````

## 7. Deployment Notes
- Deploy behind a reverse proxy (Fly.io, Railway, Render) with TLS.
- Configure `/health/live` for uptime monitoring and `/metrics/health` for dashboards.
- Use GitHub Actions or Railway cron to hit `/sync/roblox` nightly.
- Ensure `AUTOMATION_SIGNATURE_SECRET` matches the value shared with Roblox in-game scripts and the Next.js API routes.

> Update this blueprint when new integrations or tables are introduced.

## 8. Next.js Integration Touchpoints
- `web-project/lib/grpsBackendClient.ts` centralises calls to `/sync/roblox`, `/leaderboard`, `/health/live`, and `/metrics/health`.
- Store the automation base URL in `NEXT_PUBLIC_AUTOMATION_BASE_URL` (also referenced inside `config/backend.integrations.json`).
- Next.js API routes should import the helper, forward the `x-grps-signature` header, and cache-bust responses when the automation layer reports `updatedLastHour > 0`.
