# GRPS Integration Checklist — June 2025

This revision captures the wiring introduced in the current change-set so platform operators can validate the end-to-end path before a production cut-over.

## Python Automation Service → Neon Postgres (Prisma)
- `backend/app/models/player.py` and `web-project/prisma/schema.prisma` now describe the same PostgreSQL tables (`players` and `player_snapshots`).
- SQLAlchemy continues to manage ingestion updates, while Prisma consumes the exact records for leaderboard rendering.
- `backend/app/db.py` prefers `DATABASE_URL` and falls back to `PRISMA_DATABASE_URL`, making it easy to reuse the Neon connection string across runtimes.

## Automation Service → Roblox Open Cloud
- `AutomationService` publishes player payloads to Roblox DataStores after a decision is applied. The payload mirrors the FastAPI response (including context and metadata) and is scoped/keyed using the environment configuration.
- Failures are logged but do not halt automation, keeping the backend resilient when the Open Cloud API is temporarily unavailable.

## Web Portal → Automation Data
- `/web-project` now fetches from https://automation.arcfoundation.net (`/automatic-web-project`) by default while preserving Prisma fallbacks.
- IDs returned as `BigInt` are normalised to safe JavaScript numbers before hydrating React components.
- If Prisma connectivity fails the automation payload keeps the UI operational during maintenance windows.

## Environment Contracts
- Populate `.env` / `.env.local` with matching connection strings:
  - `DATABASE_URL` (shared between FastAPI and Next.js) or a dedicated `PRISMA_DATABASE_URL` for the backend.
  - Roblox Open Cloud credentials (`ROBLOX_OPEN_CLOUD_API_KEY`, `ROBLOX_UNIVERSE_ID`, `ROBLOX_DATASTORE_*`).
- Restart the FastAPI worker whenever policy JSON or database credentials change to refresh the cached configuration.

> Tip: run `npx prisma migrate dev` inside `/web-project` after updating the schema to materialise the new columns in Neon.
