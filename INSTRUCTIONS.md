# INSTRUCTIONS — Build Plan

1) Maintain `/src` Roblox bridge modules as lightweight HTTP clients that forward telemetry to the Python backend.
2) Keep shared Lua modules deterministic (policy.lua, points.lua, ranks.lua) for on-device display only.
3) Backend authority lives in `backend/app` (FastAPI + SQLAlchemy). Extend routes, services, and models here when changing gameplay rules.
4) Ensure Lua unit tests cover bridge behaviour; Python should have matching async tests when practical.
5) Next.js web (`/web-project`) stays aligned with Prisma schema produced by the Python backend and Neon Postgres.
6) Public APIs remain read-only; administrative automation stays behind authenticated REST with HMAC/Turnstile.
7) Keep `.gitignore/.gitattributes` blocking binaries and enforcing text-only diffs.
