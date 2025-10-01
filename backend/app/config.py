from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import List, Optional

from pydantic import Field, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Central configuration for the GRPS Python backend."""

    environment: str = Field("development", alias="ENVIRONMENT")
    database_url: Optional[str] = Field(None, alias="DATABASE_URL")
    prisma_database_url: Optional[str] = Field(None, alias="PRISMA_DATABASE_URL")
    roblox_group_id: int = Field(0, alias="ROBLOX_GROUP_ID")
    open_cloud_api_key: str = Field("", alias="ROBLOX_OPEN_CLOUD_API_KEY")
    default_universe_id: Optional[int] = Field(None, alias="ROBLOX_UNIVERSE_ID")
    datastore_name: str = Field("GRPS_Points", alias="ROBLOX_DATASTORE_NAME")
    datastore_scope: str = Field("global", alias="ROBLOX_DATASTORE_SCOPE")
    datastore_key_prefix: str = Field("player:", alias="ROBLOX_DATASTORE_PREFIX")
    automation_signature_secret: Optional[str] = Field(None, alias="AUTOMATION_SIGNATURE_SECRET")
    webhook_verification_key: Optional[str] = Field(None, alias="WEBHOOK_VERIFICATION_KEY")
    turnstile_secret_key: Optional[str] = Field(None, alias="TURNSTILE_SECRET_KEY")
    api_key_header: str = Field("x-grps-api-key", alias="API_KEY_HEADER")
    inbound_api_keys: List[str] = Field(default_factory=list, alias="INBOUND_API_KEYS")
    config_dir: Path = Field(Path(__file__).resolve().parents[2] / "config", alias="CONFIG_DIR")
    allowed_origins: List[str] = Field(default_factory=list, alias="ALLOWED_ORIGINS")
    api_host: str = Field("127.0.0.1", alias="API_HOST")
    api_port: int = Field(8080, alias="API_PORT")
    auto_reload: bool = Field(True, alias="API_AUTO_RELOAD")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False

    @validator("inbound_api_keys", "allowed_origins", pre=True)
    def _split_csv(cls, value):
        if isinstance(value, str):
            return [item.strip() for item in value.split(",") if item.strip()]
        return value


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Return cached settings instance."""

    return Settings()  # type: ignore[call-arg]


__all__ = ["Settings", "get_settings"]
