# INFO — RLE Group Rank Point System (GRPS)

**Version:** 1.4 • **Date:** 2025-09-30

This is the master contract/spec for GRPS. If other docs conflict, INFO.md wins.

## Key Points
- Rank progression via policy JSON; Python FastAPI backend performs authoritative writes.
- Warning thresholds: ≥4 → Suspended (Punishment_Trial, up to 14 days), ≥7 → Ban (Punishment_Severe).
- Guest is ignored by GRPS (no points/promotions/penalties).
- Read-only public API powering website at rle.arcfoundation.net backed by automation.arcfoundation.net.
- Website stack: **Vercel + Next.js 15 + Tailwind + TypeScript + ESLint**, DB: **Prisma + Neon Postgres**, security: **Cloudflare Turnstile**.
- Roblox ↔ GRPS uses HTTP snapshots + **Roblox Creator Hub Open Cloud** for authenticated ops.

## Public API Contract
- `GET /leaderboard/top?limit=25` → `{ players: [{ userId, username, rank, points, kos, wos }] }`
- `GET /leaderboard/records` → `{ kos:[...], wos:[...] }`
- `GET /player/:userId` → leaderstats + recent history

## File Map
- `/config` policy JSONs
- `/src/roblox/...` LuaU modules & tests
- `/automatic-web-project` automation API (Next.js 15) deployed at https://automation.arcfoundation.net
- `/web-project` website scaffold
- `/docs/rank_chart.svg` SVG diagram (text-only)
