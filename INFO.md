# INFO — Robloxian Lightning Empire (RLE) • Group Rank Point System (GRPS)

**Version:** 1.3 • **Date:** 2025-09-30

This single document is the **master index** and **full specification** for the GRPS program used by the **Robloxian Lightning Empire**. It merges and references the Codex guidance from **AGENTS.md**, the build steps from **INSTRUCTIONS.md**, the architecture and policy details from **STRUCTURE.md**, and the web system defined in **/web-project**. Treat `INFO.md` as the top-level contract: if there’s a conflict anywhere else, **INFO.md wins**.

---

## Table of Contents
1. [Mission & Scope](#mission--scope)  
2. [System Overview](#system-overview)  
3. [Ranks, Levels, and Policy](#ranks-levels-and-policy)  
4. [Points Economy](#points-economy)  
5. [Promotions, Warnings, Suspensions & Bans](#promotions-warnings-suspensions--bans)  
6. [Permissions & Commands](#permissions--commands)  
7. [Architecture & Modules](#architecture--modules)  
8. [Data & Storage](#data--storage)  
9. [Security Model](#security-model)  
10. [Testing Strategy](#testing-strategy)  
11. [Web Project (Next.js 15 + Tailwind)](#web-project-nextjs-15--tailwind)  
12. [Agent (Codex) Operating Rules](#agent-codex-operating-rules)  
13. [Build Plan](#build-plan)  
14. [Public API Contract](#public-api-contract)  
15. [File Map](#file-map)  
16. [Non-Binary Policy](#non-binary-policy)  
17. [How to Contribute](#how-to-contribute)  

---

## Mission & Scope
The **GRPS** (Group Rank Point System) governs **rank progression**, **activity tracking**, **commendations/warnings**, and **automated staffing workflows** for the RLE. It is thematically aligned to an **electric, modern-sci‑fi empire** while using **real-world military patterns** (time-in-rank, conduct, recommendations).

**Out of scope:** generating or storing any **binary assets** (images/audio/video). All implementations in this repo are **text-only**.

---

## System Overview
Core capabilities:
- Track **points**, **KOs/WOs**, **activity**, trainings, operations, and recommendations.
- Calculate **rank eligibility** using **policy JSON** (thresholds & time-in-rank).
- Execute **AutoPromote** decisions with full **audit logs**.
- Enforce **punishments** (trial suspension, severe ban) based on warning thresholds.
- Publish **read‑only leaderboards** for a public website at `https://rle.arcfoundation.net` (see **/web-project**).

See also: **STRUCTURE.md → System Overview**.

---

## Ranks, Levels, and Policy
The official ranks and levels are defined in **/config/policy.ranks.json** and documented in **STRUCTURE.md**. Highlights (top→bottom):

- LDR: Imperator; Supreme Council; Supreme Command; Supreme Admirals  
- CCM: Stormmarshal; Brigadier General  
- CMD: Electro Colonel; Tempest Major; Ambassador; Envoy  
- D&I: Captain II; Captain I  
- MR/LR: Arc Lieutenant II/I; Thunder Sergeant II/I; Storm Corporal II/I; Volt Specialist II/I; Shock Trooper II/I  
- L&M: Suspended; Initiate; (**Guest is ignored by GRPS**)

Levels (abbrev): **LR, MR, D&I, CMD, CCM, LDR**.

---

## Points Economy
- **Sources:** activity ticks (5m), trainings, operations, KOs/WOs (clamped), recommendations.
- **Sinks:** inactivity decay, warnings, unsportsmanlike conduct (policy-driven).
- **Caps:** daily & weekly caps to prevent farming.
- Implemented by `src/roblox/shared/points.lua`. Weights/caps in **/config/policy.points.json**.

---

## Promotions, Warnings, Suspensions & Bans
- **Promotion** checks: `minPoints`, `minTimeDays`, `requiredRecs`, and optional conduct score. Implemented by `src/roblox/shared/ranks.lua`.
- **Warning policy:**  
  - **≥4 warnings** → **Suspended** (`Punishment_Trial`) **up to 14 days** (configurable).  
  - **≥7 warnings** → **Ban** (`Punishment_Severe`).  
- **Guest** rank is **ignored** (no points/promotions/penalties).  
- Implemented in server stubs: `src/roblox/server/punishments.lua`, `/warn` in `src/roblox/server/commands.lua`.  
- Punishment config: **/config/policy.punishments.json**.

---

## Permissions & Commands
Permission mapping in **/config/permissions.json** and helpers in `src/roblox/server/permissions.lua`.

**Commands (subset):**
- `/getpoints [user?]`, `/getkos [user?]`, `/getwos [user?]`
- `/commend <user> <+points> <reason>`
- `/warn <user|group> <reason>` (triggers trial/severe per policy)
- `/promote <user> [reason]` (policy-checked; queues if not auto)
- `/deduct <user> <points> <reason>`  
All commands **audit-log** mutations.

---

## Architecture & Modules
- **Shared:** `policy.lua`, `points.lua`, `ranks.lua`
- **Server:** `permissions.lua`, `commands.lua`, `punishments.lua`, (add) `audit.lua`, `datastore.lua`, `api.lua`
- **Bot:** jobs to evaluate queues and publish leaderboard snapshots
- **Docs:** `STRUCTURE.md`, `AGENTS.md`, `INSTRUCTIONS.md`, `docs/rank_chart.svg`
- **Web:** `/web-project` (Next.js 15 + Tailwind)

Module details are elaborated in **STRUCTURE.md** and **INSTRUCTIONS.md**.

---

## Data & Storage
- Roblox DataStore (with OrderedDataStore for leaderboards).  
- Optional external **read‑only API** cache for the website (Cloudflare Worker, Node, etc.).  
- **Audit** logs are append-only JSONL with hash chaining (spec in STRUCTURE).

---

## Security Model
- Server-authoritative writes; clients only submit requests.  
- RBAC via group rank ↔ level mapping + in-experience badges.  
- HMAC for service-to-service calls; key rotation.  
- Rate limiting & circuit breakers on external endpoints.  
- Public site uses **read-only** endpoints.

---

## Testing Strategy
- **Unit tests:** calculators (points/ranks), punishments thresholds.  
- **Simulation:** promotion/demotion workloads with seeded RNG.  
- Test stubs live under `src/roblox/shared/tests` and `src/roblox/server/tests`.  
- Minimal runner at `src/roblox/shared/tests/runner.lua`.

---

## Web Project (Next.js 15 + Tailwind)
Folder: **/web-project** (domain: `https://rle.arcfoundation.net`)

- Home displays **Top 25** and **Top KOs/WOs**.  
- Uses `NEXT_PUBLIC_GRPS_API` env var to hit GRPS read-only endpoints.  
- Includes **mock API** in `app/api` for local dev (`/api/leaderboard/top`, `/api/leaderboard/records`, `/api/player/[userId]`).  
- No binary assets; Tailwind only.

---

## Agent (Codex) Operating Rules
Codex MUST follow the rules in **AGENTS.md**. Key excerpts:
- **Do not** generate or commit **binary assets**.
- Only produce: `.lua`, `.json`, `.md`, `.yml`, `.toml`, `.txt`, `.ts`, `.tsx`, `.js`, `.css`.  
- Use small, testable modules; deterministic logic; JSONL logging.  
- Obey the punishment thresholds and **Guest** ignore policy.

---

## Build Plan
Codex should follow **INSTRUCTIONS.md** step-by-step:
1. Scaffold folders (`/src`, `/config`, `/docs`, `/web-project`).
2. Implement shared modules (`policy.lua`, `points.lua`, `ranks.lua`).
3. Implement server modules (`permissions.lua`, `commands.lua`, `punishments.lua`, then `audit.lua`, `datastore.lua`, `api.lua`).  
4. UI: NEXUS panels (text/vector only).  
5. Bot: evaluation & snapshot jobs.  
6. Web: use env-based API; keep routes read-only.  
7. Tests: wire stubs to runner; add more as modules land.

---

## Public API Contract
Read-only endpoints (for the website):
- `GET /leaderboard/top?limit=25` → `{ players: [{userId, username, rank, points, kos, wos}] }`  
- `GET /leaderboard/records` → `{ kos:[...], wos:[...] }`  
- `GET /player/:userId` → leaderstats + recent history

**Caching:** send `s-maxage` headers for CDN; rate-limit by IP.  
**Privacy:** never expose audit logs via public endpoints.

---

## File Map
- **INFO.md** — you are here (master contract)  
- **README.md**, **STRUCTURE.md**, **AGENTS.md**, **INSTRUCTIONS.md** — detailed docs  
- **/config** — policy JSONs  
- **/src/roblox** — LuaU modules (server/shared) + tests + runner  
- **/web-project** — Next.js 15 + Tailwind scaffold (with mock API)  
- **/docs/rank_chart.svg** — text-only hierarchy diagram

---

## Non-Binary Policy
To avoid accidental binaries from Codex:
- No image/audio/video generation or commits.  
- If a visual is required, use **ASCII**, **SVG (text)**, or **Markdown**.  
- Block common binary extensions in `.gitignore/.gitattributes` (see INSTRUCTIONS).

---

## How to Contribute
1. Keep modules <500 lines when possible.  
2. Add tests for every calculator/validator.  
3. Update **INFO.md** when policy or endpoints change.  
4. Never bypass punishment thresholds; always audit‑log mutations.

---

**Linked references:**  
- See **AGENTS.md**, **INSTRUCTIONS.md**, **STRUCTURE.md**, and `/web-project/README.md` for deeper detail.
