from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import get_settings
from .db import get_engine
from .models import Base
from .routes import automation, health, leaderboard, players, roblox, sync

app = FastAPI(title="RLE GRPS Backend", version="1.0.0")

settings = get_settings()

if settings.allowed_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


@app.on_event("startup")
async def on_startup() -> None:
    engine = get_engine()
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)


@app.on_event("shutdown")
async def on_shutdown() -> None:
    engine = get_engine()
    await engine.dispose()


app.include_router(health.router)
app.include_router(roblox.router)
app.include_router(players.router)
app.include_router(leaderboard.router)
app.include_router(automation.router)
app.include_router(sync.router)


__all__ = ["app"]
