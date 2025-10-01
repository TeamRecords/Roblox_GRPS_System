# Current Updates & 2025 Deployment Playbook

## Snapshot — October 2025
- **Automation API Split**: `/automatic-web-project` now hosts the production Next.js API deployed to https://automation.arcfoundation.net. It shares the Prisma schema with the public portal and validates sync signatures.
- **Public Portal Refresh**: `/web-project` consumes the live automation endpoints and exposes `/api/leaderboard/refresh` for scheduled syncs. Default domain is https://rle.arcfoundation.net.
- **FastAPI Authority**: Python automation in `backend/app` still performs authoritative rank calculations, Roblox Open Cloud writes, and webhook dispatching.
- **Open Cloud Sync**: Roblox Creator Hub Open Cloud integration handled by `backend/app/services/roblox_client.py`; Roblox scripts forward snapshots through REST instead of writing DataStores directly.
- **Integration Config**: `/config/backend.integrations.json` centralises service endpoints, secrets, and feature toggles for all runtimes.

## 2025 Full Setup Checklist

### 1. Governance & Security
1. Rotate organisational secrets (Roblox API keys, database passwords, HMAC signing keys).
2. Enforce per-environment `.env` files (`.env.development`, `.env.production`) for both Python and Next.js apps.
3. Enable Cloudflare Turnstile on the public web portal and enforce server-side verification through the Python service.

### 2. Roblox Experience Deployment
1. Import the `/src/roblox` modules into Roblox Studio via Rojo or the new Roblox CLI.
2. Place `server` modules under `ServerScriptService/GRPS` and `shared` modules under `ReplicatedStorage/GRPSShared`.
3. Configure `DataStoreService` API access level to `Open Cloud` for automation and ensure ordered datastore is enabled for leaderboards.
4. Configure the new Open Cloud adapter with the API key, universe ID, datastore name, and scope (see `config/backend.integrations.json`).
5. For satellite universes (training arenas, patrol hubs, etc.), copy the three bridge scripts from `/src/roblox/shared/bridge` into `ServerScriptService/GRPSBridge` (keeping `ExperienceServer` as a Script and the other two as ModuleScripts). Update `ExperienceConfig` with the experience key, API URL, and command ranks before publishing.
6. Grant the automation service's API key permission to read/write the GRPS datastore via Roblox Open Cloud.

### 3. Python Automation Service (FastAPI)
1. Review and materialise the reference implementation in `backend/automation.md` as `backend/service.py`.
2. Create a Python 3.13 environment (uv v0.4+, poetry 1.8+, or pip-tools) and install dependencies listed in the markdown (`fastapi`, `httpx`, `pydantic`, `sqlalchemy[asyncio]`, `asyncpg`, `python-dotenv`, `redis` optional).
3. Run initial migrations using Alembic (template commands provided) to create `players`, `audits`, and `sync_jobs` tables.
4. Register service secrets in `.env` (examples in `.env.example`) and confirm FastAPI boots via `uvicorn app.main:app --reload`.

### 4. Database Provisioning
1. Provision a Postgres 15+ instance (Neon, Supabase, Railway, or self-hosted) with logical replication enabled if you plan to mirror to analytics.
2. Apply Prisma migrations (`npm run db:migrate`) in `/web-project` after updating `DATABASE_URL`.
3. Align SQLAlchemy models (Python) and Prisma schema (Next.js) so both reference identical tables/columns; the automation service seeds data consumed by the web portal.
4. If analytics warehousing is required, configure CDC to BigQuery/Snowflake via Fivetran and register read-only credentials in `backend.integrations.json`.

### 5. Web Portal Bring-Up
1. Populate `/web-project/.env.local` with `DATABASE_URL`, `NEXT_PUBLIC_AUTOMATION_BASE_URL=https://automation.arcfoundation.net`, and `TURNSTILE_SITE_KEY`.
2. Run `npm install`, `npm run lint`, and `npm run dev` to verify the leaderboard fetches from Prisma and the automation API.
3. Deploy to Vercel (or another platform) with environment variables set and Prisma Data Proxy enabled if needed for serverless cold-start mitigation.

### 6. Automation API Bring-Up
1. Populate `/automatic-web-project/.env.local` with database URLs plus `GRPS_AUTOMATION_SIGNATURE_SECRET`.
2. Run `npm install`, `npm run lint`, and `PORT=3001 npm run dev` to expose the API locally.
3. Confirm `/api/leaderboard/top` and `/api/health/live` return JSON payloads before deploying to https://automation.arcfoundation.net.

### 7. Connectivity Dry Run
1. With FastAPI running locally, execute `python backend/scripts/bootstrap.py` (script defined in `backend/automation.md`) to seed rank data and queue sync jobs.
2. Trigger the `POST /sync/roblox` endpoint to pull fresh Roblox points and confirm `players` table updates.
3. From the web project, hit `/api/leaderboard/refresh` (Next.js route) to fetch aggregated stats from the automation service via `grpsBackendClient` (new helper in `web-project/lib`).
4. Verify audit events propagate to Redis (optional) and PostgreSQL, and that webhook deliveries fire to configured Discord/Slack channels.

### 7. Monitoring & Maintenance
1. Configure uptime checks (Better Stack / Pingdom) for FastAPI health endpoint `/health/live`.
2. Ship logs to Loki or Datadog with request IDs forwarded from Roblox, FastAPI, and Next.js layers.
3. Schedule nightly `sync_jobs` via systemd timer, GitHub Actions cron, or your orchestration of choice.
4. Quarterly review `policy.*.json` files to keep rank requirements aligned with live operations.

## Next Steps
- Implement full OpenAPI schema validation and contract tests between FastAPI and Next.js.
- Add Roblox queue processing (Task Scheduler or Amazon SQS) for large-scale point adjustments.
- Integrate SSO (Roblox OAuth + Discord) to gate privileged dashboards in the portal.

Keep this file updated after every release or infrastructure change.
