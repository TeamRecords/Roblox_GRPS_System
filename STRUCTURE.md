# STRUCTURE — Architecture, Ranks, Points, and Rules

Modules: Roblox shared (policy, points, ranks), Roblox server bridge (`api.lua` HTTP client), Python FastAPI backend (`backend/app`), web-project (Next.js + Prisma).
Data: Python backend persists to Neon Postgres (SQLAlchemy) and mirrors to Roblox via Open Cloud Datastores when necessary.
Security: Python backend is authoritative, verifies API keys/HMAC headers, and drives automation decisions before invoking Roblox Open Cloud group role APIs.
Testing: Lua unit tests cover bridge semantics; Python backend should add async tests for services/routes.
