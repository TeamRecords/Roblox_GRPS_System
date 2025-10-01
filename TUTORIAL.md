# Roblox GRPS System — End-to-End Setup Guide

This tutorial walks through provisioning the database, configuring the Python
automation backend, deploying the Next.js control centre, and validating the new
automation ➜ web synchronisation pipeline.

## 1. Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Python | 3.13+ | Backend automation service |
| Node.js | 20.x | Next.js web portal |
| PostgreSQL | 15+ | Shared datastore for FastAPI + Prisma |
| npm | 10.x | Package management |
| Git | Latest | Source control |

Install system packages:

```bash
sudo apt update && sudo apt install -y build-essential python3.13 python3.13-venv postgresql-client
```

## 2. Clone & Inspect

```bash
git clone https://github.com/your-org/Roblox_GRPS_System.git
cd Roblox_GRPS_System
```

Review project structure (`backend/`, `web-project/`, `src/roblox/`).

## 3. Environment Variables

1. Copy the shared template:
   ```bash
   cp .env.example .env
   cp .env.example web-project/.env.local
   ```
2. Edit both files and replace placeholder values:
   - `DATABASE_URL` / `DIRECT_URL`: Postgres connection strings.
   - `AUTOMATION_SIGNATURE_SECRET` **and** `GRPS_AUTOMATION_SIGNATURE_SECRET`: identical HMAC secret for sync requests.
   - Roblox Open Cloud secrets (`ROBLOX_OPEN_CLOUD_API_KEY`, `ROBLOX_UNIVERSE_ID`, etc.).
   - Turnstile keys (site + secret).
   - `GRPS_SYNC_TOKEN`: arbitrary bearer token for protecting the web sync API.

> **Tip:** The backend reads `.env`; the Next.js app reads `.env.local`. Keep
> production secrets outside of version control.

## 4. Provision PostgreSQL

Create database and user (adjust values to match `.env`):

```sql
CREATE USER grps_user WITH PASSWORD 'change-me';
CREATE DATABASE grps OWNER grps_user;
GRANT ALL PRIVILEGES ON DATABASE grps TO grps_user;
```

Optional: enable extensions required by analytics or cron tooling.

## 5. Backend (FastAPI) Bring-Up

```bash
cd backend
python3.13 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Generate database schema
alembic upgrade head  # if migrations exist

# Run the service
uvicorn app.main:app --reload --port 8000
```

Verify health:

```bash
curl http://localhost:8000/health/live
```

Expected response: `{"status":"ok","timestamp":"..."}`.

## 6. Next.js Web Portal

```bash
cd web-project
npm install
npx prisma generate
npx prisma db push  # creates tables identical to the backend models
npm run dev
```

Open http://localhost:3000 to confirm the leaderboard renders. With the backend
online, the page hydrates using automation data and falls back to Prisma when
offline.

## 7. Roblox ↔ Automation Synchronisation

1. Populate Roblox DataStore via your experiences using the scripts in
   `src/roblox/` (see `/src/roblox/server/api.lua` and the Open Cloud adapter).
2. Trigger the backend sync endpoint (protected by the HMAC secret):
   ```bash
   SYNC_PAYLOAD='{"activity":"leaderboard","limit":100}'
   SIGNATURE=$(python - <<'PY'
import hashlib, hmac, os, sys
secret = os.environ.get('AUTOMATION_SIGNATURE_SECRET', 'replace-with-hex-secret')
body = sys.stdin.read().strip()
print(hmac.new(secret.encode(), body.encode(), hashlib.sha256).hexdigest())
PY
<<<"$SYNC_PAYLOAD")

   curl -X POST http://localhost:8000/sync/roblox \
     -H "Content-Type: application/json" \
     -H "x-grps-signature: $SIGNATURE" \
     -d "$SYNC_PAYLOAD"
   ```
   The response includes `{ "updated": X, "created": Y, "nextCursor": null }`.
3. From the Next.js project, mirror the automation data into Prisma:
   ```bash
   curl -X POST http://localhost:3000/api/leaderboard/refresh \
     -H "Content-Type: application/json" \
     -H "x-grps-sync-token: ${GRPS_SYNC_TOKEN}" \
     -d '{"limit":100,"triggerRobloxSync":true}'
   ```
   Response fields: `playersProcessed`, `created`, `updated`, plus the backend
   automation payload when triggered.

## 8. Roblox Game Integration Checklist

1. Import modules from `src/roblox` into Studio (Rojo or Roblox CLI).
2. Configure `ExperienceConfig` with REST endpoint + experience keys.
3. Update `OpenCloud` module with the same Open Cloud secrets used by the backend.
4. Ensure DataStore API access is set to *Open Cloud* and that the API key has
   read/write permission.
5. Publish and test by running an experience session—verify that leaderstats
   snapshots reach `/roblox/events/player-activity`.

## 9. Operational Playbook

- **Cron Sync:** Schedule `curl ... /api/leaderboard/refresh` every 5 minutes on
  Vercel/Netlify cron jobs or a lightweight server.
- **Monitoring:** Configure uptime checks against
  `http://localhost:8000/health/live` (or the production URL). Alert on non-200.
- **Secrets Rotation:** Rotate Roblox, Turnstile, and sync HMAC secrets at least
  quarterly. Update `.env` files and redeploy both services.
- **Backups:** Snapshot the Postgres database daily. Keep 30-day retention.

## 10. Troubleshooting

| Symptom | Resolution |
| --- | --- |
| `401` from `/sync/roblox` | Ensure the signature HMAC matches the backend secret. |
| `/api/leaderboard/refresh` returns `502` | Backend automation URL unreachable or misconfigured. Check `GRPS_AUTOMATION_BASE_URL`. |
| Prisma fallback empty | Confirm the sync endpoint ran and that the `players` table contains records. |
| Roblox ingestion 401 | Add the Roblox API key to `INBOUND_API_KEYS` or disable the header requirement. |

With these steps complete the GRPS automation backend, Roblox telemetry bridge,
and Next.js control panel operate as a cohesive system with reproducible
environment settings and documented sync workflows.

