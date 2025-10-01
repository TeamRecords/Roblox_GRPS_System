# RLE Public Web Project (Next.js 15 / Tailwind / Prisma)

This Next.js application powers the public-facing Robloxian Lightning Empire (RLE) GRPS portal. It
is deployed to **https://rle.arcfoundation.net** and hydrates leaderboard data from the live
automation API hosted at **https://automation.arcfoundation.net** (`/automatic-web-project`).

## Quick Start

```bash
cd web-project
npm install
cp ../.env.example .env.local
npx prisma generate && npx prisma db push
npm run dev
```

The web portal runs on `http://localhost:3000` during development. When paired with the automation
API (running on `http://localhost:3001`), the site mirrors the production integration and keeps data
in sync via the `/api/leaderboard/refresh` route.

## Key Environment Variables

| Variable | Description |
| --- | --- |
| `NEXT_PUBLIC_AUTOMATION_BASE_URL` | Public URL for the automation API (defaults to `https://automation.arcfoundation.net`). |
| `GRPS_AUTOMATION_BASE_URL` | Server-to-server URL for automation fetches; falls back to the public URL. |
| `GRPS_AUTOMATION_SIGNATURE_SECRET` | HMAC secret shared with the automation API for triggering sync jobs. |
| `GRPS_SYNC_TOKEN` | Token required to access the local `/api/leaderboard/refresh` route. |
| `DATABASE_URL` / `DIRECT_URL` | Postgres connection strings shared with Prisma. |

Refer to `../TUTORIAL.md` for a complete end-to-end setup including Roblox, FastAPI, and automation
service configuration.

## Production Notes

- Deploy via Vercel using the provided `vercel.json` and `next.config.js`.
- Configure a cron job (Vercel Cron or GitHub Actions) to invoke `/api/leaderboard/refresh`
  periodically so the Prisma cache stays aligned with automation data.
- Cloudflare Turnstile is verified through the local API route (`/api/turnstile`) before allowing
  protected submissions.
