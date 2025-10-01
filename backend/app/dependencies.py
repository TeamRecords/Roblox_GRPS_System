from __future__ import annotations

from fastapi import Depends

from sqlalchemy.ext.asyncio import AsyncSession

from .db import get_session
from .services.automation import AutomationService
from .services.calculations import CalculationService
from .services.ingestion import IngestionService


async def get_ingestion_service(session: AsyncSession = Depends(get_session)) -> IngestionService:
    calculator = CalculationService()
    return IngestionService(session, calculator)


async def get_automation_service(session: AsyncSession = Depends(get_session)) -> AutomationService:
    return AutomationService(session)


__all__ = ["get_ingestion_service", "get_automation_service"]
