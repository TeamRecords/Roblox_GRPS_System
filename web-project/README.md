# RLE Web Project (Vercel / Next.js 15 / Tailwind / TS / Prisma / Turnstile)

Quick start:
```
cd web-project
npm i
cp .env.example .env.local
npx prisma generate && npx prisma db push
npm run dev
```

Local dev uses built-in mock API routes under `/api/*`. In prod, set `NEXT_PUBLIC_AUTOMATION_BASE_URL` to the Python automation service (`https://automation.example.com`) so the site hydrates from `/leaderboard/top` and `/leaderboard/records`.
Turnstile: client retrieves token; server verifies via `POST /api/turnstile` which forwards to the automation service `/webhooks/turnstile` endpoint.
Roblox Open Cloud: use for authenticated tasks; publish read-only snapshots for the site to consume via HTTP, or delegate to the automation `/sync/roblox` endpoint.
