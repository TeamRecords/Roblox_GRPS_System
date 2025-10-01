# STRUCTURE — Architecture, Ranks, Points, and Rules

Modules: Roblox shared (policy, points, ranks), Roblox server bridge (`api.lua` HTTP client), Python FastAPI backend (`backend/app`), automation web project (`/automatic-web-project` Next.js API), public portal (`/web-project`).
Data: FastAPI and both Next.js runtimes share the same Postgres schema via Prisma/SQLAlchemy so automation responses equal the leaderboard view.
Security: Automation API and portal use matching HMAC headers (`GRPS_AUTOMATION_SIGNATURE_SECRET`) and optional sync tokens; backend still performs authoritative Roblox writes.
Testing: Lua unit tests cover bridge semantics; Python backend and both Next.js apps should run `npm run lint`/`npm run build` before releases.
