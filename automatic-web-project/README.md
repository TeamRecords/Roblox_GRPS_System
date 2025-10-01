# RLE Automation Web Project (Next.js 15 / Tailwind / Prisma)

This application hosts the live API routes that power the Robloxian Lightning Empire (RLE)
GRPS leaderboard and automation workflows. It is deployed to
`https://automation.arcfoundation.net` and is consumed by the public-facing portal in
`/web-project` (`https://rle.arcfoundation.net`).

## Features

- **REST API** with stable routes for leaderboard, health, metrics, and Roblox sync requests.
- **Prisma ORM** shared with the web portal to ensure data parity.
- **HMAC Authenticated Sync** endpoint that mirrors the payload expected by the web portal.
- **Next.js 15** App Router using the same TailwindCSS toolchain as the public site for ease of
  maintenance.

## Quick Start

```bash
cd automatic-web-project
npm install
cp ../.env.example .env.local
npx prisma generate && npx prisma db push
npm run dev
```

The service defaults to `http://localhost:3001` in development (set `PORT=3001`) so it can run
alongside the public web portal on port 3000. Update `.env.local` with the automation-specific
secrets described in the workspace root `TUTORIAL.md`.

## API Surface

| Route | Method | Description |
| --- | --- | --- |
| `/api/leaderboard/top` | `GET` | Returns the latest ranked players for the leaderboard view. |
| `/api/leaderboard/records` | `GET` | Aggregates top KOs and WOs for highlight cards. |
| `/api/metrics/health` | `GET` | Reports total players and updates in the past hour. |
| `/api/health/live` | `GET` | Liveness probe used by monitors. |
| `/api/sync/roblox` | `POST` | Authenticated sync trigger validating the HMAC signature shared with the portal. |

## Connecting to the Public Portal

Set the following variables in `/web-project/.env.local` (or the Vercel project environment):

```
NEXT_PUBLIC_AUTOMATION_BASE_URL=https://automation.arcfoundation.net
GRPS_AUTOMATION_BASE_URL=https://automation.arcfoundation.net
```

With those values in place the portal automatically hydrates from the live automation data while
still supporting local fallbacks for development.
