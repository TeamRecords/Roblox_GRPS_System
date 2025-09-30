# AGENTS — Rules & Prompts for Codex

This document defines how **Codex** (or any code‑generator agent) must operate when implementing GRPS.

## Non‑Binary Policy (MUST)
- DO NOT generate or commit **images, audio, or video** files.
- Only produce **text** artifacts: `.lua`, `.md`, `.json`, `.toml`, `.yml`, `.txt`.
- If an asset is required, create a **placeholder README** describing the asset and where to fetch it externally.
- Never inline base64 blobs.
- Prefer code fences and file diffs; never attach binaries.

## File/Repo Rules
- Use Unix LF endings, UTF‑8.
- Keep each module under 500 lines per file when possible.
- Deterministic output: seeded RNGs for simulations.

## Style
- Roblox LuaU; server‑authoritative design.
- Pure functions for calculators: `points.calculate`, `ranks.next`, `policy.check`.
- Logging: structured JSON lines.

## Step‑Down Prompts (Codex should follow)
1. **Scaffold** the repo folders in `/src` and `/config`.
2. Implement `src/shared/policy.lua` to load and cache JSON policies.
3. Implement calculators in `src/shared/points.lua` and `src/shared/ranks.lua`.
4. Server endpoints (RemoteFunctions/Events) in `src/server/api.lua`.
5. Client NEXUS UI in `src/client/ui/*` (no images; vector shapes/TextLabels only).
6. Command handlers in `src/server/commands.lua` (permission‑gated).
7. AutoPromote Bot stubs in `src/bot/*` (text only; no schedulers yet).
8. Unit tests in `src/shared/tests/*` using minimal test runner.
9. Simulation script in `src/bot/jobs/sim_promotions.lua`.

## Acceptance Criteria
- Policy JSON drives thresholds without code changes.
- All mutations are audit‑logged with actor, reason, and hash of prior record.
- Leaderboard stable and reproducible.
- Commands permission‑checked; failing commands never mutate state.
