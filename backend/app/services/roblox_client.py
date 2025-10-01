from __future__ import annotations

from typing import Any, Dict, Optional

import httpx

from ..config import get_settings

ROBLOX_API_BASE = "https://apis.roblox.com"
ROBLOX_GROUPS_BASE = "https://groups.roblox.com"


class RobloxClient:
    """Thin wrapper around Roblox Open Cloud REST endpoints."""

    def __init__(self, api_key: Optional[str] = None, group_id: Optional[int] = None):
        settings = get_settings()
        self.api_key = api_key or settings.open_cloud_api_key
        self.group_id = group_id or settings.roblox_group_id
        self.timeout = 30.0

    async def _request(
        self,
        method: str,
        url: str,
        *,
        json: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        headers = {"x-api-key": self.api_key, "Content-Type": "application/json"}
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.request(method, url, headers=headers, json=json, params=params)
            response.raise_for_status()
            if response.content:
                return response.json()
            return {}

    async def get_user_group_role(self, user_id: int) -> Optional[Dict[str, Any]]:
        url = f"{ROBLOX_GROUPS_BASE}/v1/users/{user_id}/groups/roles"
        payload = await self._request("GET", url)
        for entry in payload.get("data", []):
            if entry.get("group", {}).get("id") == self.group_id:
                return entry.get("role")
        return None

    async def update_group_role(self, user_id: int, role_id: int) -> None:
        url = f"{ROBLOX_GROUPS_BASE}/v1/groups/{self.group_id}/users/{user_id}"
        await self._request("PATCH", url, json={"roleId": role_id})

    async def list_datastore_entries(
        self,
        universe_id: int,
        datastore_name: str,
        *,
        scope: str = "global",
        prefix: Optional[str] = None,
        limit: Optional[int] = None,
        cursor: Optional[str] = None,
    ) -> Dict[str, Any]:
        url = (
            f"{ROBLOX_API_BASE}/datastores/v1/universes/{universe_id}/standard-datastores/datastore/entries"
        )
        params: Dict[str, Any] = {
            "datastoreName": datastore_name,
            "scope": scope,
        }
        if prefix:
            params["prefix"] = prefix
        if limit is not None:
            params["limit"] = limit
        if cursor:
            params["cursor"] = cursor

        return await self._request("GET", url, params=params)

    async def read_datastore_entry(
        self,
        universe_id: int,
        datastore_name: str,
        *,
        key: str,
        scope: str = "global",
    ) -> Dict[str, Any]:
        url = (
            f"{ROBLOX_API_BASE}/datastores/v1/universes/{universe_id}/standard-datastores/datastore/entries/entry"
        )
        params = {
            "datastoreName": datastore_name,
            "scope": scope,
            "entryKey": key,
        }
        return await self._request("GET", url, params=params)

    async def write_datastore(self, universe_id: int, datastore_name: str, scope: str, key: str, value: Dict[str, Any]) -> None:
        url = (
            f"{ROBLOX_API_BASE}/datastores/v1/universes/{universe_id}/standard-datastores/datastore/entries/entry"
        )
        params = {"datastoreName": datastore_name, "scope": scope, "entryKey": key}
        await self._request("POST", url, json=value, params=params)


__all__ = ["RobloxClient"]
