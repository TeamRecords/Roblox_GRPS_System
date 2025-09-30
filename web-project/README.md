# RLE Web Project (Vercel / Next.js 15 / Tailwind / TS / Prisma / Turnstile)

Quick start:
```
cd web-project
npm i
cp .env.example .env.local
npx prisma generate && npx prisma db push
npm run dev
```

Local dev uses built-in mock API routes under `/api/*`. In prod, set `NEXT_PUBLIC_GRPS_API` to your read-only GRPS endpoint.
Turnstile: client retrieves token; server verifies via `POST /api/turnstile`.
Roblox Open Cloud: use for authenticated tasks; publish read-only snapshots for the site to consume via HTTP.
