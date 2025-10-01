from __future__ import annotations

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from backend.app.models import Base, Player
from backend.app.services.leaderboard import LeaderboardService


@pytest_asyncio.fixture
async def session() -> AsyncSession:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    session_maker = async_sessionmaker(engine, expire_on_commit=False)
    async with session_maker() as session:
        yield session
    await engine.dispose()


@pytest.mark.asyncio
async def test_fetch_top_players_orders_by_points(session: AsyncSession) -> None:
    session.add_all(
        [
            Player(
                user_id=1,
                username="Alpha",
                rank="Shock Trooper I",
                rank_points=150,
                kos=20,
                wos=5,
            ),
            Player(
                user_id=2,
                username="Bravo",
                rank="Shock Trooper II",
                rank_points=350,
                kos=15,
                wos=3,
            ),
            Player(
                user_id=3,
                username="Charlie",
                rank="Volt Specialist I",
                rank_points=350,
                kos=25,
                wos=1,
            ),
        ]
    )
    await session.commit()

    service = LeaderboardService(session)
    players = await service.fetch_top_players(limit=3)

    assert [entry["userId"] for entry in players] == [3, 2, 1]
    assert players[0]["points"] == 350
    assert players[0]["kos"] == 25


@pytest.mark.asyncio
async def test_fetch_record_holders_returns_distinct_lists(session: AsyncSession) -> None:
    session.add_all(
        [
            Player(
                user_id=10,
                username="Delta",
                rank="Shock Trooper I",
                rank_points=80,
                kos=40,
                wos=18,
            ),
            Player(
                user_id=11,
                username="Echo",
                rank="Shock Trooper II",
                rank_points=200,
                kos=55,
                wos=9,
            ),
            Player(
                user_id=12,
                username="Foxtrot",
                rank="Volt Specialist I",
                rank_points=420,
                kos=33,
                wos=40,
            ),
        ]
    )
    await session.commit()

    service = LeaderboardService(session)
    records = await service.fetch_record_holders(limit=2)

    assert [entry["userId"] for entry in records["kos"]] == [11, 10]
    assert [entry["userId"] for entry in records["wos"]] == [12, 10]
