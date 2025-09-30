# STRUCTURE — Architecture, Ranks, Points, and Rules

## 1) System Overview
GRPS has four cooperating modules:
1. **Core Service** — Roblox scripts + DataStore abstraction for rank points, activity, and policy rules.
2. **NEXUS UI** — In‑experience UI for members and a privileged panel for Command.
3. **Ops CLI** — Admin console commands (prefixed `/`) for audit‑logged operations.
4. **AutoPromote Bot** — Out‑of‑experience service account that reads policy, evaluates members, and executes promotions/demotions via Roblox APIs.

### Data & Storage
- Primary: Roblox **DataStore** (OrderedDataStore for leaderboards).
- Secondary: External API (REST/GraphQL) proxy with signed webhooks (optional).
- Audit: Append‑only logs per action with actor, target, reason, and hash chain.

## 2) Rank Ladder (RLE)
**Unchanged Leadership & Command**  
- Imperator [LDR]  
- Supreme Council [LDR]  
- Supreme Command [LDR]  
- Supreme Admirals [LDR]  

**Central Command**  
- General [CCM]  
- Brigadier General [CCM]  

**Command / Diplomatic**  
- Ambassador [CMD]  
- Envoy [CMD]  

**Captains**  
- Captain II [D&I]  
- Captain I [D&I]

**Customized Progression**
- Shock Trooper I [LR]  
- Shock Trooper II [LR]  
- Volt Specialist I [LR]  
- Volt Specialist II [MR]  
- Storm Corporal I [MR]  
- Storm Corporal II [MR]  
- Thunder Sergeant I [MR]  
- Thunder Sergeant II [MR]  
- Arc Lieutenant I [MR]  
- Arc Lieutenant II [MR]  
- Tempest Major [CMD]  
- Electro Colonel [CMD]  
- Stormmarshal [CCM]

> Levels: LR = Low Rank, MR = Medium Rank, D&I = Diplomat/Intermediate, CMD = Command, CCM = Central Command, LDR = Leadership

## 3) Points Economy
- **Sources**: Activity ticks (time in server), **KOs/WOs** deltas, training attendance, operations participation, commendations, mission objectives, staff recommendations.
- **Sinks**: Inactivity decay, formal warnings/punishments, friendly‑fire penalties, unsportsmanlike conduct.
- **Caps**: Per‑day and per‑week caps prevent farming and inflate‑control.
- **Anti‑abuse**: Per‑action cooldowns, anomaly detection (sudden spikes), server IP/instance correlation, and audit reviews.

### Baseline Weights (example)
- Activity Tick (5 min): +1
- Training Complete: +15
- Operation Complete: +25
- KO: +0.25 (PVP only; clamped)
- WO (death): −0.10 (clamped; no negative farming)
- Recommendation (Cmd/CCM): +10/+20 (rate‑limited)

## 4) Promotion Rules
- Each rank R has **MinPoints[R]**, **MinTimeInRank[R]**, **ConductScore≥T**, and optionally **Required Recs**.
- **AutoPromote**: If all conditions met, queue for bot verification and execute.
- **Grace Windows**: On demotion triggers (e.g., severe conduct), lock promotions for N days.
- **Manual Overrides**: Cmd/CCM can override with reason; all overrides are audit‑logged.

Example (illustrative—tune in policy JSON):
```
Shock Trooper I -> Shock Trooper II:
  MinPoints: 50, MinTimeInRank: 2 days, NoWarnings: true

Arc Lieutenant II -> Tempest Major:
  MinPoints: 1200, MinTimeInRank: 14 days, Recs: 1 (CCM)
```
All thresholds are configurable in `config/policy.ranks.json`.

## 5) Permissions Matrix (subset)
- **Member**: view self stats, leaderboard, shouts.
- **Sergeants+**: open squad tools, file commendations/warnings (limited).
- **Lieutenants+**: approve training results, request promotions.
- **Captains+**: approve operations, mass add points (bounded sets).
- **Cmd**: search, inspect, add/deduct points, warn groups, approve/dismiss promotion queues.
- **CCM/LDR**: strategy flags, policy edits, final promotions to CCM/LDR.

## 6) Commands
- `/getpoints [user?]`
- `/getkos [user?]`  `/getwos [user?]`
- `/commend <user> <+points> <reason>`
- `/warn <user|group> <reason>`
- `/promote <user> [reason]` (policy‑checked; queues if not auto)
- `/deduct <user> <points> <reason>`

All commands are permission‑gated and audit‑logged.

## 7) UI (NEXUS)
- **Member Panel**: Shouts, profile, current vs next rank, joined divisions, avatar/name, leaderboard.
- **Command Panel**: Search, member drill‑down, points add/deduct, warnings, batch ops, recommendations viewer.
- Real‑time status: API link, datastore health, bot status.

## 8) Security
- RBAC by in‑group role + in‑experience badge.
- Signed server‑to‑server calls (HMAC w/ rotation).
- Anti‑tamper: server‑authoritative writes; client only reads and submits requests.
- Rate limiting & circuit breakers for external API calls.

## 9) Files & Config (expected in implementation)
```
/src
  /roblox
    /client
    /server
    /shared
  /bot
    /jobs
    /lib
/config
  policy.ranks.json
  policy.points.json
  permissions.json
/docs (this repo)
```

## 10) Testing
- Unit tests for calculators and validators.
- Simulation scripts for promotions/demotions under random workloads.
- Golden data snapshots for deterministic leaderboard ordering.
