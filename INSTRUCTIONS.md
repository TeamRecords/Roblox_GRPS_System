# INSTRUCTIONS — Build Plan

1) Scaffold `/src`, `/config`, `/docs`, `/web-project`.
2) Implement shared modules (policy.lua, points.lua, ranks.lua).
3) Implement server (permissions.lua, commands.lua, punishments.lua, audit.lua, datastore.lua, api.lua).
4) Add unit tests and wire runner.
5) Next.js web: env-based API, Tailwind, TS, ESLint, Prisma (Neon), Turnstile.
6) Publish read-only endpoints; never expose audit logs.
7) Add `.gitignore/.gitattributes` rules to block binaries.
