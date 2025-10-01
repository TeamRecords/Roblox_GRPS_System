# GRPS Automation Service — FastAPI Implementation

The Roblox GRPS automation stack now lives in `backend/app`. The service is a
Python 3.13 FastAPI application that receives telemetry from Roblox experiences,
calculates rank changes, persists player state to Neon Postgres, and invokes
Roblox Open Cloud APIs for automated promotions, demotions, suspensions, and
bans. Its public-facing data contract is exposed through the Next.js automation
API (`/automatic-web-project`, https://automation.arcfoundation.net).

## Runtime Overview

- **Framework**: FastAPI + Pydantic v2
- **Database**: SQLAlchemy (async) targeting Neon Postgres (compatible with Prisma schema)
- **HTTP Client**: `httpx` for Roblox Open Cloud + outbound webhooks
- **Auth**: HMAC-style API key via the `x-grps-api-key` header, optional
  additional signing/HMAC can be layered on reverse proxies
- **Schema Sources**: Policy JSON in `/config/policy.*.json` and shared Lua
  modules remain the single source of truth for ranks/points definitions

```
backend/app/
├── main.py                # FastAPI app factory + router wiring
├── config.py              # Pydantic settings loader (env-driven)
├── db.py                  # SQLAlchemy engine + session helpers
├── models/                # ORM models (`Player`, `PlayerSnapshot`)
├── routes/                # FastAPI routers (health, roblox, players, automation)
├── schemas.py             # Pydantic request/response models
├── services/
│   ├── rank_policy.py     # Loads /config/policy.ranks.json with privilege flags
│   ├── calculations.py    # Converts snapshots to structured player context
│   ├── ingestion.py       # Persists snapshots + history
│   ├── automation.py      # Promotion/demotion/suspension logic + Roblox calls
│   └── roblox_client.py   # Minimal Roblox Open Cloud wrapper
└── requirements.txt       # Dependency lock (pip install -r requirements.txt)
```

## Core Data Flow

1. **Roblox Experience ➜ FastAPI**: In-game scripts call
   `POST /roblox/events/player-activity` (see `src/roblox/server/api.lua`). The
   payload mirrors the public leaderstats contract plus warning/punishment data.
2. **Ingestion**: `IngestionService` validates and upserts the player record,
   stores a JSON snapshot in `player_snapshots`, and enriches the record with
   next/previous rank metadata via `CalculationService`.
3. **Automation** *(optional per request)*: If the caller sets
   `x-grps-evaluate: true`, the service invokes `AutomationService.evaluate` to
   determine the best action (promote, demote, suspend, ban, or none). When
   `x-grps-apply: true`, the decision is executed immediately—`RobloxClient`
   updates the user's group role via Open Cloud.
4. **Persistence**: Player rows are written to Postgres; Next.js/Prisma consumes
   the same tables to power leaderboards. Automation decisions update the
   records in-place so Roblox snapshots always reflect the authoritative state.
5. **Roblox Mirror** *(optional)*: Use `RobloxClient.write_datastore` if the web
   experience needs Datastore parity. Hook this into `AutomationService` or a
   background worker as required.

## REST Endpoints

| Method | Path                                   | Description |
| ------ | -------------------------------------- | ----------- |
| GET    | `/health/live`                         | Basic uptime signal |
| POST   | `/roblox/events/player-activity`       | Ingests a Roblox snapshot, optionally evaluates/apply automation |
| GET    | `/players/{userId}`                    | Returns enriched player context (leaderstats + next/prev rank) |
| POST   | `/automation/decisions`                | Manual automation trigger from dashboards or cron jobs |

### Snapshot Contract (`POST /roblox/events/player-activity`)

Headers:

- `x-grps-api-key`: shared secret (optional when `INBOUND_API_KEYS` empty)
- `x-roblox-experience`: experience key (training, nexus, etc.)
- `x-grps-actor`: Roblox userId performing the action (for audit)
- `x-grps-evaluate`: "true"/"false" flag to run automation engine
- `x-grps-apply`: "true"/"false" flag to apply the returned decision

Body (JSON):

```json
{
  "userId": 12345678,
  "username": "ArcTrooper",
  "displayName": "Arc",
  "rank": "Volt Specialist II",
  "rankPoints": 520,
  "kos": 84,
  "wos": 12,
  "warnings": 1,
  "recommendations": 0,
  "punishmentStatus": null,
  "experience": {
    "universeId": 987654321,
    "placeId": 1234567890,
    "server": "vip-3"
  }
}
```
Response (`SnapshotIngestResponse`):

```json
{
  "player": {
    "userId": 12345678,
    "username": "ArcTrooper",
    "rank": "Volt Specialist II",
    "rankPoints": 520,
    "nextRank": "Storm Corporal I",
    "nextRankRequiredPoints": 750,
    "previousRank": "Shock Trooper II",
    "previousRankRequiredPoints": 150,
    "warnings": 1,
    "privileged": false,
    "decisionsBlocked": false,
    "lastSyncedAt": "2025-03-01T18:15:44Z"
  },
  "decision": {
    "action": "PROMOTE",
    "targetRank": "Storm Corporal I",
    "reason": "Eligible for promotion",
    "apply": true,
    "requestId": "9ac0f5e3a6a7e551"
  }
}
```

## Configuration

Environment variables consumed by `backend/app/config.py`:

```
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/grps
ROBLOX_GROUP_ID=123456
ROBLOX_OPEN_CLOUD_API_KEY=rbx-oc-...
ROBLOX_UNIVERSE_ID=987654321
ROBLOX_DATASTORE_NAME=GRPS_Points
ROBLOX_DATASTORE_SCOPE=global
ROBLOX_DATASTORE_PREFIX=player:
INBOUND_API_KEYS=rbx-ingest-key-1,rbx-ingest-key-2
ALLOWED_ORIGINS=https://grps.example.com,http://localhost:3000
```

The service also reads policy files from `/config` at runtime (see
`CalculationService` and `RankPolicy`). Updating `policy.ranks.json` or
`permissions.json` automatically changes backend behaviour without redeploying
Roblox scripts.

## Development

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

While the development server is running you can execute the Lua test suite in
parallel (`lua src/roblox/server/tests/runner.lua`) to validate the bridge logic.

## Deployment Checklist

1. **Secrets**: Configure environment variables on the hosting platform (Fly,
   Railway, Render, etc.) with production values.
2. **Database**: Apply migrations (Alembic or Prisma) to ensure `players` and
   `player_snapshots` exist. The SQLAlchemy models mirror the Prisma schema used
   by `/web-project`.
3. **Networking**: Restrict ingress with WAF/IP allow-lists and require the
   `x-grps-api-key` header for Roblox ingestion. Optionally add HMAC signatures
   similar to previous revisions.
4. **Monitoring**: Point uptime checks at `/health/live`. Forward FastAPI logs
   to your central logging stack with request IDs from Roblox.
5. **Roblox Open Cloud**: Grant the automation API key access to the group and
   Datastore (read/write).

## Extending the Service

- New rank requirements ➜ update `/config/policy.ranks.json` and, if the Roblox
  UI needs it, mirror changes in `src/roblox/shared/policy.lua`.
- Additional automation logic ➜ extend `AutomationService._resolve_action` and
  add unit tests (Python) for the new rules.
- Outbound integrations (Discord, Slack, etc.) ➜ create a new service module and
  call it after `AutomationService.evaluate` when decisions are applied.
- Scheduled jobs ➜ add a background worker or cron hitting
  `POST /automation/decisions` for bulk reviews.

The FastAPI service is now the single source of truth for promotions and rank
points. Roblox scripts collect telemetry; everything else happens on the Python
stack.
