--[[
Command handlers for the GRPS server component.

Commands are bundled into an object for deterministic behaviour. This
allows us to inject mocked dependencies for offline tests while keeping
the production API straightforward.
--]]

local Policy = require(script.Parent.Parent.shared.policy)
local Permissions = require(script.Parent.permissions)
local Punishments = require(script.Parent.punishments)

local Commands = {}
Commands.__index = Commands

local function defaultLogger(payload)
  local actorName = "server"
  if payload.actor and payload.actor.Name then
    actorName = payload.actor.Name
  end

  local message = payload.message or payload.action or "COMMAND"
  print(("[CMD] %s %s"):format(actorName, message))
end

function Commands.new(policy, options)
  options = options or {}
  policy = policy or Policy.load(options.policyOptions)

  local instance = setmetatable({}, Commands)
  instance.policy = policy
  instance.permissions = options.permissions or Permissions.new(policy, options.permissionOptions)
  instance.punishments = options.punishments or Punishments.new(policy, options.punishmentOptions)
  instance.logger = options.logger or defaultLogger
  return instance
end

function Commands:warn(actor, targetUserId, reason)
  if not self.permissions:canWarn(actor) then
    self.logger({
      action = "WARN_DENIED",
      actor = actor,
      targetUserId = targetUserId,
      reason = reason,
    })
    return false, "NO_PERMISSION"
  end

  local actorId = actor and actor.UserId or 0
  local warnCount = self.punishments:incrementWarn(targetUserId, actorId, reason)
  local status = self.punishments:evaluate(targetUserId)

  if status == "TRIAL" then
    local untilTimestamp = self.punishments:applyTrialSuspension(targetUserId, actorId, warnCount)
    self.logger({
      action = "WARN_TRIAL",
      actor = actor,
      targetUserId = targetUserId,
      count = warnCount,
      untilTimestamp = untilTimestamp,
      reason = reason,
    })
  elseif status == "SEVERE" then
    self.punishments:applySevereBan(targetUserId, actorId, warnCount)
    self.logger({
      action = "WARN_SEVERE",
      actor = actor,
      targetUserId = targetUserId,
      count = warnCount,
      reason = reason,
    })
  else
    self.logger({
      action = "WARN_RECORDED",
      actor = actor,
      targetUserId = targetUserId,
      count = warnCount,
      reason = reason,
    })
  end

  return true, { count = warnCount, status = status }
end

return Commands
