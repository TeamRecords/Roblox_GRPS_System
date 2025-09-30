# RLE Web Project (Next.js 15 + TailwindCSS)

Domain: https://rle.arcfoundation.net

## Quick Start
```bash
cd web-project
npm i
cp .env.example .env.local
npm run dev
```
Set `NEXT_PUBLIC_GRPS_API` to your GRPS API base (e.g., Cloudflare Workers, Vercel, or your own).

## Pages
- `/` — Global leaderboard, top KOs/WOs, player cards.
The page uses server actions to fetch JSON from GRPS endpoints:
- `GET /leaderboard/top` → `{ players: [{userId, username, rank, points, kos, wos}] }`
- `GET /leaderboard/records` → `{ kos: [...], wos: [...] }`

## Notes
- No binary assets; Tailwind only.
- Add custom components in `/components`.


## Mock API (for local dev)
This scaffold includes mock JSON routes under `app/api` so the UI renders without a backend.

- `GET /api/leaderboard/top`
- `GET /api/leaderboard/records`
- `GET /api/player/[userId]`

To switch the UI from mock routes to your real GRPS API, set `NEXT_PUBLIC_GRPS_API` and update fetch calls in `app/page.tsx`.
