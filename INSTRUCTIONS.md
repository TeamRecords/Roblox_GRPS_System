# INSTRUCTIONS — Exact Build Plan for Codex (v2)

Additions to prior instructions:
- Implement `/warn` command in `src/roblox/server/commands.lua` so it:
  - Verifies actor permissions (`permissions.canWarn`),
  - Calls `punishments.incrementWarn`,
  - If threshold hit, enqueues `punishment.applyTrialSuspension` or `punishment.applySevereBan`,
  - Sends notice to actor and target (chat/private) and writes audit entry.

- Create `src/roblox/server/punishments.lua` (outlined in AGENTS.md).
- Ensure `Guest` role id is present in `config/permissions.json` with `ignored: true` and code checks that early to bypass points & promotions.

Testing:
- Add tests in `src/roblox/server/tests/test_punishments.lua` that simulate repeated warnings and verify suspension and ban logic, including suspended_until calculation and promotion locks.
