# Current Updates & 2025 Deployment Playbook

## Snapshot — March 2025
- **GRPS Core**: Lua modules for policy, points, ranks, permissions, punishments, audit, and datastore remain source-of-truth for in-game automation.
- **Web Portal**: Next.js 15 + Prisma scaffold (see `/web-project`) prepared for Neon Postgres or self-hosted Postgres.
- **Automation Back-End**: New Python FastAPI service blueprint (`backend/automation.md`) orchestrates sync jobs, audit mirroring, and webhook delivery.
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
4. Grant the automation service's API key permission to read/write GRPS datastore via Roblox Open Cloud.

### 3. Python Automation Service (FastAPI)
1. Review and materialise the reference implementation in `backend/automation.md` as `backend/service.py`.
2. Create a Python 3.12 environment (uv v0.4+, poetry 1.8+, or pip-tools) and install dependencies listed in the markdown (`fastapi`, `httpx`, `pydantic`, `sqlalchemy[asyncio]`, `asyncpg`, `python-dotenv`, `redis` optional).
3. Run initial migrations using Alembic (template commands provided) to create `players`, `audits`, and `sync_jobs` tables.
4. Register service secrets in `.env` (examples below) and confirm FastAPI boots via `uvicorn backend.service:app --reload`.

```env
DATABASE_URL=postgresql+asyncpg://grps_bot:change-me@127.0.0.1:5432/grps
ROBLOX_OPEN_CLOUD_API_KEY=rbx-oc-...
ROBLOX_UNIVERSE_ID=000000000
WEBHOOK_VERIFICATION_KEY=base64-hmac-secret
TURNSTILE_SECRET_KEY=1x0000000000000000000000000000000AA
AUTOMATION_SIGNATURE_SECRET=hmac-shared-secret
```

### 4. Database Provisioning
1. Provision a Postgres 15+ instance (Neon, Supabase, Railway, or self-hosted) with logical replication enabled if you plan to mirror to analytics.
2. Apply Prisma migrations (`npm run db:migrate`) in `/web-project` after updating `DATABASE_URL`.
3. Align SQLAlchemy models (Python) and Prisma schema (Next.js) so both reference identical tables/columns; the automation service seeds data consumed by the web portal.
4. If analytics warehousing is required, configure CDC to BigQuery/Snowflake via Fivetran and register read-only credentials in `backend.integrations.json`.

### 5. Web Portal Bring-Up
1. Populate `/web-project/.env.local` with `DATABASE_URL`, `NEXT_PUBLIC_AUTOMATION_BASE_URL`, and `TURNSTILE_SITE_KEY`.
2. Run `npm install` and `npm run dev` to verify the leaderboard fetches from Prisma and falls back gracefully if automation is offline.
3. Deploy to Vercel (or another platform) with environment variables set and [Prisma Data Proxy](https://www.prisma.io/docs/data-platform/data-proxy) enabled for serverless cold-start mitigation.

### 6. Connectivity Dry Run
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
