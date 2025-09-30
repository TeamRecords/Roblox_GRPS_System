# STRUCTURE — Architecture, Ranks, Points, and Rules (v2)

## Key behavioral notes (new)
- **Guest**: role is strictly for non-members and must be **ignored** by GRPS modules (no points, no promotions, no penalties).
- **Warning & Punishment Policy**:
  - Warnings are tracked as `warn_count` per user in audit logs and datastore.
  - If `warn_count > 3` (i.e. 4 or more), system automatically moves the user to **Suspended** role and labels action as `Punishment_Trial`. Duration: up to **14 days** (configurable via `policy.punishments.trial_days`).
  - If `warn_count > 6` (i.e. 7 or more), system escalates to **ban** (remove from group or set `banned=true`) and labels action as `Punishment_Severe` (permanent unless reviewed).
  - All such actions are **audit‑logged** with actor (Cmd/CCM), reason, count snapshot, and timestamps. Automatic moves by AutoPromote Bot must include the trigger and last warning events.
- **Temporary Suspensions**: Suspended members retain profile data but cannot earn points, cannot use commands requiring LR or above, and cannot access NEXUS features (CommandPanel and Leaderboards).

## Rank Ladder (snapshot)
- Imperator [LDR]
- Supreme Council [LDR]
- Supreme Command [LDR]
- Supreme Admirals [LDR]

- Stormmarshal [CCM]
- Brigadier General [CCM]
- Electro Colonel [CMD]
- Tempest Major [CMD]

- Ambassador [CMD]
- Envoy [CMD]

- Captain II [D&I]
- Captain I [D&I]

- Arc Lieutenant II [MR]
- Arc Lieutenant I [MR]
- Thunder Sergeant II [MR]
- Thunder Sergeant I [MR]
- Storm Corporal II [MR]
- Storm Corporal I [MR]
- Volt Specialist II [LR/MR]
- Volt Specialist I [LR]
- Shock Trooper II [LR]
- Shock Trooper I [LR]

- Suspended [L&M]  (system‑moved via Punishment_Trial)
- Initiate [L&M]
- Guest [L&M]  (ignored by system)

## Punishment fields (policy)
- `punishments.trial_days` (int): how long Suspended lasts by default
- `punishments.trial_lock_promotion` (bool): lock promotions while suspended
- `punishments.escalation_warn_threshold` (int): e.g., 7 => ban

## Enforcement flow (simplified)
1. A CMD/CCM issues `/warn <user> <reason>` which increments `warn_count` and writes audit event.
2. After increment, `promotions.eval` or `punishment.eval` checks thresholds.
3. If `warn_count >= punish.trial_threshold` (config=4), system enacts `Punishment_Trial`: set role=Suspended, suspend points gains, set `suspended_until = now + trial_days`.
4. If `warn_count >= punish.severe_threshold` (config=7), system enacts `Punishment_Severe`: ban flag, disable account activities, and notify CCM/LDR for manual review.
5. AutoPromote Bot must **never** automatically ban without explicit severe threshold hit; all auto actions remain reversible only by LDR/CCM with audit entries.

## Config storage
- `config/policy.ranks.json` — rank thresholds and levels.
- `config/policy.points.json` — point weights & caps.
- `config/policy.punishments.json` — warning thresholds & trial duration.
- `config/permissions.json` — mapping of ranks to command permissions.
