# Roblox GRPS System — Full Deployment Guide (2025)

This guide walks through provisioning every component of the Robloxian Lightning Empire (RLE) GRPS
stack: Roblox experience hooks, Python automation service, the live automation API hosted in
`/automatic-web-project`, and the public portal in `/web-project`.

---

## 1. Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| Node.js | 20.x | Required for both Next.js applications. |
| npm | 10.x | Package manager used by each web project. |
| Python | 3.13+ | Runs the FastAPI automation worker under `/backend`. |
| PostgreSQL | 15+ | Shared database consumed by Prisma and SQLAlchemy. |
| Git | Latest | Source control & deployment tooling. |

Install base packages (Ubuntu/Debian example):

```bash
sudo apt update
sudo apt install -y build-essential python3.13 python3.13-venv postgresql-client
```

---

## 2. Clone the Repository & Inspect Structure

```bash
git clone https://github.com/your-org/Roblox_GRPS_System.git
cd Roblox_GRPS_System
```

Key directories:

- `/src` — Roblox LuaU bridge modules that forward telemetry to automation services.
- `/backend` — Python FastAPI automation worker.
- `/automatic-web-project` — Next.js 15 API deployment (https://automation.arcfoundation.net).
- `/web-project` — Public Next.js 15 portal (https://rle.arcfoundation.net).
- `/config` — Policy JSON and integration manifests consumed across runtimes.

Review `STRUCTURE.md` for a high-level architecture diagram and integration points.

---

## 3. Environment Variables

1. Copy the template:
   ```bash
   cp .env.example .env
   cp .env.example backend/.env
   cp .env.example automatic-web-project/.env.local
   cp .env.example web-project/.env.local
   ```
2. Populate secrets per runtime (see `.env.example` for grouped sections).
   - **Roblox**: `ROBLOX_OPEN_CLOUD_API_KEY`, `ROBLOX_UNIVERSE_ID`, datastore configuration.
   - **Automation HMAC**: `AUTOMATION_SIGNATURE_SECRET` and `GRPS_AUTOMATION_SIGNATURE_SECRET` must match across
     the FastAPI backend, automation web project, and public portal.
   - **Web Portal Sync**: `GRPS_SYNC_TOKEN` protects `/api/leaderboard/refresh`.
   - **Domains**: leave defaults for production (`https://automation.arcfoundation.net` and
     `https://rle.arcfoundation.net`) or switch to localhost for development.

> **Tip:** Use `.env.local` for any Next.js runtime so secrets never enter source control or
> deployment logs.

---

## 4. Database Provisioning

Create a PostgreSQL database and user (adjust credentials as needed):

```sql
CREATE USER grps_user WITH PASSWORD 'change-me';
CREATE DATABASE grps OWNER grps_user;
GRANT ALL PRIVILEGES ON DATABASE grps TO grps_user;
```

For hosted options (Neon, Supabase, Railway), enable connection pooling for serverless
deployments. Ensure both Prisma (`DATABASE_URL`) and SQLAlchemy (`PRISMA_DATABASE_URL`) target the
same instance so automation and the public portal share identical tables.

---

## 5. Backend Automation Service (FastAPI)

```bash
cd backend
python3.13 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Database migrations / schema sync
alembic upgrade head  # if migrations are available

# Launch the worker
uvicorn app.main:app --reload --port 8000
```

Sanity check the service:

```bash
curl http://localhost:8000/health/live
```

Expect `{"status":"ok","timestamp":"..."}`.

---

## 6. Automation Web Project (`/automatic-web-project`)

This Next.js deployment powers the live API (`https://automation.arcfoundation.net`). It shares the
Prisma schema with the public site so both agree on player state.

```bash
cd automatic-web-project
npm install
npx prisma generate
npx prisma db push
PORT=3001 npm run dev
```

### Key Endpoints

- `GET /api/leaderboard/top` — Ranked players for the public leaderboard.
- `GET /api/leaderboard/records` — Highlight stats (KOs/WOs).
- `GET /api/metrics/health` — Operational metrics for dashboards.
- `GET /api/health/live` — Liveness probe for monitors.
- `POST /api/sync/roblox` — Validates the HMAC signature and returns recent automation updates.

> **Local Pairing:** Run this service on port `3001` so the public portal (port `3000`) can forward
> requests without conflicts. Update `.env.local` values if you choose a different port.

---

## 7. Public Web Project (`/web-project`)

```bash
cd web-project
npm install
npx prisma generate
npx prisma db push
npm run dev
```

When the automation API is running, the portal fetches live data from
`http://localhost:3001`. Adjust `.env.local` if your automation instance is hosted elsewhere.
Use `npm run lint` and `npm run build` to validate deployments before pushing to Vercel.

### Sync Workflow

1. Trigger the automation API (optional) by calling the portal endpoint:
   ```bash
   curl -X POST http://localhost:3000/api/leaderboard/refresh \
     -H "x-grps-sync-token: ${GRPS_SYNC_TOKEN}" \
     -d '{"triggerRobloxSync":true,"limit":100}'
   ```
2. The portal signs the payload with `GRPS_AUTOMATION_SIGNATURE_SECRET` and calls
   `POST /api/sync/roblox` on the automation API.
3. Automation responds with player updates, which the portal then mirrors into Prisma.

---

## 8. Roblox Integration Checklist

1. Import modules from `/src/roblox` via Rojo or the Roblox CLI.
2. Configure `ExperienceConfig` with the automation API base URL and API key header defined in
   `.env` (`API_KEY_HEADER`).
3. Ensure your Open Cloud API key has read/write access to the GRPS datastore and the relevant
   experience IDs.
4. Validate telemetry: experience scripts should POST snapshots to the FastAPI backend
   (`/backend/app`) which in turn writes to the shared Postgres database.

---

## 9. Production Deployment Flow

1. **Automation API** (`/automatic-web-project`)
   - Deploy to Vercel/Netlify (or a container platform) using environment variables from `.env`.
   - Configure a health check against `/api/health/live`.

2. **Public Portal** (`/web-project`)
   - Deploy to Vercel using the same Prisma database credentials.
   - Set `NEXT_PUBLIC_AUTOMATION_BASE_URL` and `GRPS_AUTOMATION_BASE_URL` to
     `https://automation.arcfoundation.net`.
   - Schedule a cron job to call `/api/leaderboard/refresh` every 5–10 minutes.

3. **FastAPI Backend** (`/backend`)
   - Deploy on your preferred Python hosting (Docker, Fly.io, Railway).
   - Share `AUTOMATION_SIGNATURE_SECRET` with the automation API.
   - Configure logging/monitoring pipelines.

4. **Roblox Experience**
   - Publish updated scripts with the production automation endpoint.
   - Smoke test rank adjustments and datastore updates before the public launch.

---

## 10. Testing & Maintenance

- **Linting**: Run `npm run lint` in both web directories before committing.
- **Build Verification**: Run `npm run build` to ensure Next.js can compile server and client bundles.
- **Database Backups**: Snapshot Postgres daily and retain at least 30 days of backups.
- **Secrets Rotation**: Rotate Roblox Open Cloud keys, Turnstile secrets, and HMAC signatures at
  least quarterly. Update every runtime simultaneously.
- **Monitoring**: Track uptime for `/api/health/live`, `/api/metrics/health`, and the FastAPI
  `/health/live` route. Forward logs to your observability stack.

Following this guide results in a fully wired GRPS deployment with aligned automation, public
surface, and Roblox integrations.
