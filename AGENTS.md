# AGENTS — Rules & Prompts for Codex (v2)

Updates:
- Codex **MUST** implement and respect the new `punishments` config and enforce the `Guest` ignore rule.
- Automatic actions must produce an audit log entry and a human-readable `reason` field.

### Enforcement specifics for Codex-generated code
- Use a central helper `src/roblox/server/punishments.lua` with functions:
  - `incrementWarn(userId, actorId, reason)` -> returns new warn_count and whether action triggered.
  - `applyTrialSuspension(userId, actorId, warn_count)` -> sets suspended_until and role, logs event.
  - `applySevereBan(userId, actorId, warn_count)` -> sets banned flag, logs event, notifies CCM/LDR channels.
- All functions must be idempotent and testable. No direct file or binary writes—only datastore and audit JSON lines.

### Non-binary policy reminder (MUST)
- DO NOT output or commit binary files.
- Create placeholder READMEs for assets if needed.
