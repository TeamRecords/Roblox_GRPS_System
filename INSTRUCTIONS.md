# Integration Notes — Roblox ↔ Web

## Public API endpoints (to implement in GRPS)
- `GET /leaderboard/top?limit=25` — returns global top players by points.
- `GET /leaderboard/records` — returns top 3–5 KOs and WOs all-time.
- `GET /player/:userId` — returns leaderstats for a specific user.

These should read from OrderedDataStore snapshots created by a scheduled job inside the Roblox game server (or your out-of-experience bot).

## Security
- Endpoints are read-only for the website; no write routes.
- Rate-limit by IP and add cache headers (`s-maxage`) for CDN caching.
- Never expose internal audit data via public API.

## Deployment
- Point `rle.arcfoundation.net` to your host (e.g., Vercel) and set `NEXT_PUBLIC_GRPS_API` env var.
