# INSTRUCTIONS — Exact Build Plan for Codex

Follow these tasks in order. Generate **text‑only** files.

## 0) Scaffold
Create folders:
```
/src/roblox/client /src/roblox/server /src/roblox/shared
/src/bot/jobs /src/bot/lib
/config /docs
```
Add a root `LICENSE` (MIT placeholder) and `README.md` (from this repo doc).

## 1) Config JSON
Create:
- `/config/policy.ranks.json` — rank names, minPoints, minTimeDays, requiredRecs, level.
- `/config/policy.points.json` — weights, caps, cooldowns.
- `/config/permissions.json` — each command’s minLevel (LR/MR/D&I/CMD/CCM/LDR).

## 2) Shared Modules (Lua)
- `src/roblox/shared/policy.lua` — loads JSON via HttpService; caches; validates schema.
- `src/roblox/shared/ranks.lua` — functions: `nextRank(user)`, `meetsThresholds(user, rank)`, `levelOf(rank)`.
- `src/roblox/shared/points.lua` — accumulation, decay, clamps, anti‑abuse.

## 3) Server Modules
- `src/roblox/server/audit.lua` — append‑only JSONL audit writer; returns event id.
- `src/roblox/server/permissions.lua` — group role ↔ level mapping; helpers `can(actor, action)`.
- `src/roblox/server/api.lua` — RemoteEvents/Functions for UI, guarded by `permissions`.
- `src/roblox/server/commands.lua` — handlers for `/getpoints`, `/getkos`, `/getwos`, `/commend`, `/warn`, `/promote`, `/deduct`.
- `src/roblox/server/promotions.lua` — queue evaluator; calls Roblox group rank APIs.
- `src/roblox/server/datastore.lua` — safe wrapper around DataStore/OrderedDataStore with retries.

## 4) Client (NEXUS UI)
- `src/roblox/client/ui/Root.lua` — screenswitch and status bar (API health, bot status).
- `src/roblox/client/ui/MemberPanel.lua` — profile, next‑rank widget, divisions.
- `src/roblox/client/ui/Leaderboard.lua` — ordered store list.
- `src/roblox/client/ui/CommandPanel.lua` — search, member view, batch actions.

UI uses **no binary assets**; only TextLabels, Frames, and vector primitives.

## 5) Bot Stubs
- `src/bot/lib/api.lua` — REST wrapper (text only).
- `src/bot/jobs/evaluate_queue.lua` — promotion evaluation from policy.
- `src/bot/jobs/sim_promotions.lua` — deterministic simulation (seeded).

## 6) Tests
- `src/roblox/shared/tests/test_ranks.lua` — thresholds & transitions.
- `src/roblox/shared/tests/test_points.lua` — caps & anti‑abuse.
- `src/roblox/server/tests/test_permissions.lua` — command gates.

## 7) Policies — Seed Data
Populate rank list using RLE names in **STRUCTURE.md**. Include levels (LR/MR/D&I/CMD/CCM/LDR) and example thresholds.

## 8) Non‑Binary Guardrails
- Add `.gitattributes` content in repo README (user will create the file):
```
*.png -text -diff linguist-generated
*.jpg -text -diff linguist-generated
*.gif -text -diff linguist-generated
*.mp3 -text -diff linguist-generated
*.wav -text -diff linguist-generated
*.mp4 -text -diff linguist-generated
*.mov -text -diff linguist-generated
```
- Add `.gitignore` section (user will create the file):
```
# Block binaries
*.png
*.jpg
*.gif
*.mp3
*.wav
*.mp4
*.mov
# Build artifacts
/build
/out
/dist
```

## 9) Deliverables
Codex should produce only the text files listed above and the Lua/JSON modules. No images/audio/video.
