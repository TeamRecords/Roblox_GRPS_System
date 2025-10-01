from __future__ import annotations

import json
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Dict, Iterable, List, Optional

from ..config import get_settings


@dataclass(frozen=True)
class Rank:
    name: str
    min_points: int
    min_time_days: int
    level: str
    privileged: bool = False
    is_punishment: bool = False
    role_id: Optional[int] = None


class RankPolicy:
    """Loads and evaluates GRPS rank configuration."""

    PRIVILEGED_LEVELS = {"CMD", "CCM", "LDR"}

    def __init__(self, ranks: Iterable[Rank]):
        ordered = sorted(ranks, key=lambda rank: rank.min_points)
        self._ranks: List[Rank] = ordered
        self._by_name: Dict[str, Rank] = {rank.name: rank for rank in ordered}

    @classmethod
    def from_config(cls) -> "RankPolicy":
        settings = get_settings()
        path = Path(settings.config_dir) / "policy.ranks.json"
        with path.open("r", encoding="utf-8") as handle:
            payload = json.load(handle)
        ranks: List[Rank] = []
        for descriptor in payload.get("ranks", []):
            rank = Rank(
                name=descriptor["name"],
                min_points=int(descriptor.get("minPoints", 0)),
                min_time_days=int(descriptor.get("minTimeDays", 0)),
                level=descriptor.get("level", "LR"),
                privileged=bool(
                    descriptor.get("privileged", False)
                    or descriptor.get("level") in cls.PRIVILEGED_LEVELS
                ),
                is_punishment=bool(descriptor.get("isPunishment", False)),
                role_id=descriptor.get("roleId"),
            )
            ranks.append(rank)
        return cls(ranks)

    def get_rank(self, name: str) -> Optional[Rank]:
        return self._by_name.get(name)

    def rank_for_points(self, points: int) -> Optional[Rank]:
        current = None
        for rank in self._ranks:
            if points >= rank.min_points:
                current = rank
            else:
                break
        return current

    def next_rank(self, points: int) -> Optional[Rank]:
        candidate = None
        for rank in self._ranks:
            if points < rank.min_points and not rank.is_punishment:
                candidate = rank
                break
        return candidate

    def previous_rank(self, points: int) -> Optional[Rank]:
        current = self.rank_for_points(points)
        if not current:
            return None
        return self.previous_rank_by_name(current.name)

    def previous_rank_by_name(self, name: str) -> Optional[Rank]:
        descriptor = self._by_name.get(name)
        if descriptor is None:
            return None
        index = self._ranks.index(descriptor)
        while index > 0:
            index -= 1
            candidate = self._ranks[index]
            if not candidate.is_punishment:
                return candidate
        return None

    def next_rank_by_name(self, name: str) -> Optional[Rank]:
        descriptor = self._by_name.get(name)
        if descriptor is None:
            return None
        index = self._ranks.index(descriptor)
        while index + 1 < len(self._ranks):
            index += 1
            candidate = self._ranks[index]
            if not candidate.is_punishment:
                return candidate
        return None

    def adjacent_ranks(self, current_name: Optional[str]) -> tuple[Optional[Rank], Optional[Rank]]:
        if current_name:
            descriptor = self._by_name.get(current_name)
        else:
            descriptor = None
        if descriptor is None:
            return None, self._ranks[0] if self._ranks else None
        index = self._ranks.index(descriptor)
        previous = None
        next_rank = None
        if index > 0:
            previous = self._ranks[index - 1]
        if index + 1 < len(self._ranks):
            next_rank = self._ranks[index + 1]
        return previous, next_rank

    def is_privileged(self, rank_name: Optional[str]) -> bool:
        if not rank_name:
            return False
        descriptor = self._by_name.get(rank_name)
        if not descriptor:
            return False
        return descriptor.privileged


@lru_cache(maxsize=1)
def get_rank_policy() -> RankPolicy:
    return RankPolicy.from_config()


__all__ = ["Rank", "RankPolicy", "get_rank_policy"]
