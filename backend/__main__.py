from __future__ import annotations

import logging
import os
import socket
from contextlib import closing
from pathlib import Path
from typing import Iterable

import uvicorn

from .app.config import get_settings

LOGGER = logging.getLogger("backend.server")


def _env_lookup(keys: Iterable[str]) -> str | None:
    for key in keys:
        value = os.getenv(key)
        if value:
            return value
    return None


def _find_ephemeral_port(host: str) -> int:
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
        sock.bind((host, 0))
        return int(sock.getsockname()[1])


def _is_socket_permission_error(error: OSError) -> bool:
    if isinstance(error, PermissionError):
        return True
    win_error = getattr(error, "winerror", None)
    if win_error is not None:
        return win_error == 10013
    return getattr(error, "errno", None) in {13}


def main() -> None:
    logging.basicConfig(level=logging.INFO)

    settings = get_settings()
    host = _env_lookup(("GRPS_BACKEND_HOST", "API_HOST")) or settings.api_host
    port_value = _env_lookup(("GRPS_BACKEND_PORT", "PORT", "API_PORT"))
    try:
        port = int(port_value) if port_value is not None else settings.api_port
    except ValueError as exc:  # pragma: no cover - defensive guard
        raise SystemExit(f"Invalid port value provided via environment: {port_value!r}") from exc

    reload_enabled = settings.environment == "development" and settings.auto_reload
    reload_dirs = [str(Path(__file__).resolve().parent / "app")]
    config = uvicorn.Config(
        "backend.app.main:app",
        host=host,
        port=port,
        reload=reload_enabled,
        reload_dirs=reload_dirs,
        factory=False,
    )

    try:
        uvicorn.Server(config).run()
        return
    except OSError as error:
        if not _is_socket_permission_error(error):
            raise

        fallback_port = _find_ephemeral_port(host)
        LOGGER.warning(
            "Port %s is not accessible on this system (error %s). Falling back to %s.",
            port,
            getattr(error, "winerror", getattr(error, "errno", "unknown")),
            fallback_port,
        )

        fallback_config = uvicorn.Config(
            "backend.app.main:app",
            host=host,
            port=fallback_port,
            reload=reload_enabled,
            reload_dirs=reload_dirs,
            factory=False,
        )
        uvicorn.Server(fallback_config).run()


if __name__ == "__main__":  # pragma: no cover - manual invocation entry point
    main()
