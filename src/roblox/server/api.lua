--[[
Server-side application facade for the GRPS.

The API coordinates policy evaluation, permission checks, audit logging
and persistence. It exposes methods that match the public HTTP contract
used by the web project but keeps everything as pure Lua so the same
logic can run during offline testing.
--]]

local Policy = require(script.Parent.Parent.shared.policy)
local Points = require(script.Parent.Parent.shared.points)
local Permissions = require(script.Parent.permissions)
local Punishments = require(script.Parent.punishments)
local Commands = require(script.Parent.commands)
local Audit = require(script.Parent.audit)
local DataStore = require(script.Parent.datastore)
local OpenCloud = require(script.Parent.open_cloud)

local Api = {}
Api.__index = Api

local function deepCopy(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = deepCopy(inner)
  end
  return copy
end

local function actorId(actor)
  if not actor then
    return 0
  end

  if type(actor) == "table" then
    return actor.UserId or actor.userId or actor.id or 0
  end

  if typeof and typeof(actor) == "Instance" then
    local ok, result = pcall(function()
      return actor.UserId
    end)
    if ok then
      return result or 0
    end
  end

  return 0
end

local function resolveRoleName(payload, record)
  return payload.role or payload.rank or (record and (record.rank or record.role))
end

local function defaultClock()
  return os.time()
end

function Api.new(options)
  options = options or {}

  local policy = options.policy or Policy.load(options.policyOptions)
  local dataStore = options.dataStore or DataStore.new({ clock = options.clock, historyLimit = options.historyLimit })
  local audit = options.audit or Audit.new({ clock = options.clock, static = { component = "api" } })
  local permissions = options.permissions or Permissions.new(policy, options.permissionOptions)
  local punishments = options.punishments or Punishments.new(policy, options.punishmentOptions)
  local clock = options.clock or defaultClock

  local commands = options.commands or Commands.new(policy, {
    permissions = permissions,
    punishments = punishments,
    logger = function(payload)
      audit:log(payload)
    end,
  })

  local openCloudAdapter = options.openCloud
  if not openCloudAdapter and options.openCloudOptions then
    openCloudAdapter = OpenCloud.new(options.openCloudOptions)
  end

  local instance = setmetatable({}, Api)
  instance._policy = policy
  instance._store = dataStore
  instance._audit = audit
  instance._permissions = permissions
  instance._punishments = punishments
  instance._commands = commands
  instance._clock = clock
  instance._historyLimit = options.historyLimit
  instance._openCloud = openCloudAdapter
  instance._openCloudLogSuccess = options.openCloudLogSuccess == true
  return instance
end

function Api:_now()
  return self._clock()
end

function Api:_canEarn(roleName)
  if not roleName then
    return false
  end

  return self._permissions:canEarn({ role = roleName, rank = roleName })
end

function Api:_applyHistory(record, entry)
  record.history = record.history or {}
  table.insert(record.history, entry)
end

function Api:_syncOpenCloud(record, context)
  if not self._openCloud or not record then
    return
  end

  context = context or {}
  local ok, success, payloadOrError, response = pcall(function()
    return self._openCloud:writePlayerSnapshot(record, { now = context.now, matchVersion = context.matchVersion })
  end)

  local auditPayload = {
    action = "OPEN_CLOUD_SYNC",
    userId = record.userId,
    source = context.source,
    success = false,
  }

  if not ok then
    auditPayload.error = tostring(success)
    self._audit:log(auditPayload)
    return
  end

  auditPayload.success = success == true
  if auditPayload.success then
    if response and type(response) == "table" then
      auditPayload.status = response.StatusCode
      if response.Headers then
        auditPayload.version = response.Headers["roblox-entry-version"]
      end
    end
    if not (context.logSuccess or self._openCloudLogSuccess) then
      return
    end
  else
    auditPayload.error = payloadOrError
    if response and type(response) == "table" then
      auditPayload.status = response.StatusCode or response.StatusMessage
    end
  end

  self._audit:log(auditPayload)
end

function Api:_buildContext(record, now, payload)
  local context = {}
  for key, value in pairs(payload.context or {}) do
    context[key] = value
  end

  context.now = context.now or now
  if payload.event and payload.event.duration then
    context.activityDuration = context.activityDuration or payload.event.duration
  end
  context.lastKoAt = context.lastKoAt or record.lastKoAt
  return context
end

local function copyTotals(record)
  return {
    points = record.points,
    daily = record.totals and record.totals.daily or 0,
    weekly = record.totals and record.totals.weekly or 0,
  }
end

function Api:recordEvent(actor, payload)
  assert(type(payload) == "table", "payload table required")
  assert(type(payload.userId) == "number", "payload.userId number required")
  assert(type(payload.event) == "table", "payload.event table required")
  assert(payload.event.type, "payload.event.type required")

  local now = payload.now or self:_now()
  local targetUserId = payload.userId
  local actorIdentifier = actorId(actor)

  local updatedRecord
  local result
  updatedRecord, result = self._store:updatePlayer(targetUserId, function(record)
    if payload.username then
      record.username = payload.username
    end
    if payload.rank then
      record.rank = payload.rank
      record.role = payload.rank
    end

    local roleName = resolveRoleName(payload, record)
    if not self:_canEarn(roleName) then
      return record, { ok = false, reason = "NOT_PERMITTED" }
    end

    local totals = {
      daily = record.totals and record.totals.daily or 0,
      weekly = record.totals and record.totals.weekly or 0,
    }

    local context = self:_buildContext(record, now, payload)
    local delta, reason = Points.resolve(payload.event, totals, self._policy.points, context)
    if reason then
      return record, { ok = false, reason = reason }
    end

    if payload.event.type == "ko" then
      record.kos = (record.kos or 0) + (payload.event.magnitude or 1)
      record.lastKoAt = context.now
    elseif payload.event.type == "wo" then
      record.wos = (record.wos or 0) + (payload.event.magnitude or 1)
    end

    record.points = (record.points or 0) + delta
    record.totals = record.totals or { daily = 0, weekly = 0 }
    record.totals.daily = (record.totals.daily or 0) + delta
    record.totals.weekly = (record.totals.weekly or 0) + delta

    local entry = {
      at = now,
      actor = actorIdentifier,
      type = payload.event.type,
      delta = delta,
      totals = copyTotals(record),
    }

    if payload.metadata then
      entry.metadata = deepCopy(payload.metadata)
    end

    self:_applyHistory(record, entry)

    return record, {
      ok = true,
      delta = delta,
      totals = copyTotals(record),
      entry = entry,
    }
  end, { now = now })

  local auditPayload = {
    action = "POINT_EVENT",
    userId = targetUserId,
    actorId = actorIdentifier,
    event = payload.event.type,
  }

  if result then
    auditPayload.success = result.ok or false
    auditPayload.delta = result.delta
    auditPayload.reason = result.reason
  end

  self._audit:log(auditPayload)

  if not result or not result.ok then
    return false, result and result.reason or "UNKNOWN"
  end

  self:_syncOpenCloud(updatedRecord, {
    source = "POINT_EVENT",
    now = now,
  })

  return true, result
end

function Api:warn(actor, targetUserId, reason)
  local success, payload = self._commands:warn(actor, targetUserId, reason)

  local now = self:_now()
  local actorIdentifier = actorId(actor)
  local updatedRecord

  if success then
    updatedRecord = select(1, self._store:updatePlayer(targetUserId, function(record)
      record.warns = payload.count
      local entry = {
        at = now,
        actor = actorIdentifier,
        type = "warn",
        delta = 0,
        status = payload.status,
      }
      self:_applyHistory(record, entry)
      return record
    end, { now = now }))
  end

  self._audit:log({
    action = "WARN_COMMAND",
    actorId = actorIdentifier,
    userId = targetUserId,
    reason = reason,
    success = success,
    status = payload and payload.status,
  })

  if success then
    self:_syncOpenCloud(updatedRecord, {
      source = "WARN_COMMAND",
      now = now,
    })
  end

  return success, payload
end

function Api:getPlayer(userId)
  local record = self._store:getPlayer(userId)
  if not record then
    return nil
  end

  local punishment = self._punishments:getState(userId)
  return {
    player = {
      userId = record.userId,
      username = record.username,
      rank = record.rank,
      points = record.points,
      kos = record.kos,
      wos = record.wos,
      warns = record.warns,
      totals = copyTotals(record),
    },
    history = deepCopy(record.history or {}),
    punishment = punishment,
  }
end

function Api:getLeaderboardTop(limit)
  return { players = self._store:leaderboardTop(limit) }
end

function Api:getLeaderboardRecords(limit)
  return self._store:records(limit)
end

function Api:getPolicy()
  return Policy.deepCopy(self._policy)
end

return Api
