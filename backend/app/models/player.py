from __future__ import annotations

from datetime import datetime

from sqlalchemy import BigInteger, Boolean, Column, DateTime, Integer, JSON, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Player(Base):
    __tablename__ = "players"

    user_id = Column(BigInteger, primary_key=True, autoincrement=False)
    username = Column(String(64), nullable=False)
    display_name = Column(String(64), nullable=True)
    rank = Column(String(64), nullable=False)
    previous_rank = Column(String(64), nullable=True)
    next_rank = Column(String(64), nullable=True)
    rank_points = Column(Integer, nullable=False, default=0)
    kos = Column(Integer, nullable=False, default=0)
    wos = Column(Integer, nullable=False, default=0)
    warnings = Column(Integer, nullable=False, default=0)
    recommendations = Column(Integer, nullable=False, default=0)
    punishment_status = Column(String(64), nullable=True)
    punishment_expires_at = Column(DateTime, nullable=True)
    privileged = Column(Boolean, nullable=False, default=False)
    metadata_payload = Column("metadata", JSON, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    last_synced_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class PlayerSnapshot(Base):
    __tablename__ = "player_snapshots"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    user_id = Column(BigInteger, nullable=False, index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)
    payload = Column(JSON, nullable=False)
    source = Column(String(64), nullable=False, default="roblox")
    experience_key = Column(String(128), nullable=True)
    actor_user_id = Column(BigInteger, nullable=True)


__all__ = ["Base", "Player", "PlayerSnapshot"]
