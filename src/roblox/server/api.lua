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
local OpenCloudRegistry = require(script.Parent.open_cloud_registry)

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

local function normaliseExperience(experience)
  if type(experience) ~= "table" then
    return nil
  end

  local result = {}
  if experience.key or experience.experienceKey then
    result.key = experience.key or experience.experienceKey
  end
  if experience.name then
    result.name = experience.name
  end
  if experience.universeId or experience.universeID then
    local value = tonumber(experience.universeId or experience.universeID)
    if value then
      result.universeId = value
    end
  end
  if experience.placeId or experience.placeID then
    local value = tonumber(experience.placeId or experience.placeID)
    if value then
      result.placeId = value
    end
  end
  if experience.server or experience.shard then
    result.server = experience.server or experience.shard
  end
  if next(result) == nil then
    return nil
  end
  return result
end

local function buildOpenCloudRegistry(options, openCloudAdapter)
  if options.openCloudRegistry then
    return options.openCloudRegistry
  end

  local entries = {}
  local defaultKey = options.defaultUniverseKey

  if options.openCloud then
    if typeof == nil or typeof(options.openCloud) ~= "Instance" then
      if options.openCloud.writePlayerSnapshot then
        table.insert(entries, {
          key = options.defaultUniverseKey or "default",
          adapter = options.openCloud,
          universeId = options.openCloudOptions and options.openCloudOptions.universeId,
          default = true,
        })
      else
        for key, value in pairs(options.openCloud) do
          if type(value) == "table" and value.writePlayerSnapshot then
            table.insert(entries, {
              key = key,
              adapter = value,
              universeId = value.universeId,
              default = defaultKey == key,
            })
          else
            local entry = deepCopy(value)
            entry.key = entry.key or key
            table.insert(entries, entry)
          end
        end
      end
    end
  elseif openCloudAdapter then
    table.insert(entries, {
      key = options.defaultUniverseKey or "default",
      adapter = openCloudAdapter,
      universeId = options.openCloudOptions and options.openCloudOptions.universeId,
      default = true,
    })
  end

  local openCloudOptions = options.openCloudOptions
  if openCloudOptions then
    if openCloudOptions.universes then
      for _, entry in ipairs(openCloudOptions.universes) do
        local copy = deepCopy(entry)
        copy.key = copy.key or copy.experienceKey or tostring(copy.universeId or "universe")
        table.insert(entries, copy)
      end
      defaultKey = defaultKey or openCloudOptions.defaultKey
    else
      local copy = deepCopy(openCloudOptions)
      copy.key = copy.key or copy.experienceKey or "default"
      copy.default = copy.default ~= false
      table.insert(entries, copy)
    end
  end

  if #entries == 0 then
    return nil
  end

  return OpenCloudRegistry.new({
    defaultKey = defaultKey,
    entries = entries,
  })
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
  if not openCloudAdapter and options.openCloudOptions and not options.openCloudOptions.universes then
    openCloudAdapter = OpenCloud.new(options.openCloudOptions)
  end

  local openCloudRegistry = buildOpenCloudRegistry(options, openCloudAdapter)

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
  instance._openCloudRegistry = openCloudRegistry
  instance._openCloudDefaultKey = openCloudRegistry and openCloudRegistry:defaultKey() or options.defaultUniverseKey
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

function Api:_resolveOpenCloudEntry(experience)
  if self._openCloudRegistry then
    local entry = self._openCloudRegistry:resolve(experience)
    if entry then
      return entry
    end
  end

  if self._openCloud then
    return {
      adapter = self._openCloud,
      key = self._openCloudDefaultKey or (experience and experience.key) or "default",
      universeId = experience and experience.universeId,
    }
  end

  return nil
end

function Api:_syncOpenCloud(record, context)
  if not record then
    return
  end

  context = context or {}
  local experience = normaliseExperience(context.experience)
  local entry = self:_resolveOpenCloudEntry(experience)
  if not entry or not entry.adapter then
    return
  end

  local ok, success, payloadOrError, response = pcall(function()
    return entry.adapter:writePlayerSnapshot(record, {
      now = context.now,
      matchVersion = context.matchVersion,
    })
  end)

  local auditPayload = {
    action = "OPEN_CLOUD_SYNC",
    userId = record.userId,
    source = context.source,
    success = false,
    experienceKey = experience and experience.key or entry.key,
    universeId = experience and experience.universeId or entry.universeId,
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
  local experience = normaliseExperience(payload.experience)

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

    if experience then
      entry.experience = deepCopy(experience)
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

  if experience then
    auditPayload.experienceKey = experience.key
    auditPayload.universeId = experience.universeId
  end

  self._audit:log(auditPayload)

  if not result or not result.ok then
    return false, result and result.reason or "UNKNOWN"
  end

  self:_syncOpenCloud(updatedRecord, {
    source = "POINT_EVENT",
    now = now,
    experience = experience,
  })

  return true, result
end

function Api:warn(actor, targetUserId, reason, options)
  options = options or {}
  local experience = normaliseExperience(options.experience)
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
    if experience then
      entry.experience = deepCopy(experience)
    end
    self:_applyHistory(record, entry)
    return record
  end, { now = now }))
  end

  local auditPayload = {
    action = "WARN_COMMAND",
    actorId = actorIdentifier,
    userId = targetUserId,
    reason = reason,
    success = success,
    status = payload and payload.status,
  }

  if experience then
    auditPayload.experienceKey = experience.key
    auditPayload.universeId = experience.universeId
  end

  self._audit:log(auditPayload)

  if success and experience then
    updatedRecord = updatedRecord or self._store:getPlayer(targetUserId)
  end

  if success then
    self:_syncOpenCloud(updatedRecord, {
      source = "WARN_COMMAND",
      now = now,
      experience = experience,
    })
  end

  return success, payload
end

function Api:adjustPoints(actor, payload)
  assert(type(payload) == "table", "payload table required")
  assert(type(payload.userId) == "number", "payload.userId number required")
  assert(type(payload.amount) == "number", "payload.amount number required")
  assert(type(payload.reason) == "string" and payload.reason ~= "", "payload.reason string required")

  local experience = normaliseExperience(payload.experience)
  local actorIdentifier = actorId(actor)
  local now = payload.now or self:_now()

  local ok, commandPayload = self._commands:adjustPoints(actor, payload.userId, payload.amount, payload.reason, {
    metadata = payload.metadata,
  })

  local auditPayload = {
    action = "POINT_ADJUST",
    actorId = actorIdentifier,
    userId = payload.userId,
    requestedAmount = payload.amount,
    reason = payload.reason,
    success = ok,
  }

  if experience then
    auditPayload.experienceKey = experience.key
    auditPayload.universeId = experience.universeId
  end

  if not ok then
    auditPayload.reasonCode = commandPayload
    self._audit:log(auditPayload)
    return false, commandPayload
  end

  local appliedDelta = commandPayload.amount
  local updatedRecord, entry = self._store:updatePlayer(payload.userId, function(record)
    if payload.username then
      record.username = payload.username
    end
    if payload.rank then
      record.rank = payload.rank
      record.role = payload.rank
    end

    record.points = (record.points or 0) + appliedDelta
    record.totals = record.totals or { daily = 0, weekly = 0 }
    record.totals.daily = (record.totals.daily or 0) + appliedDelta
    record.totals.weekly = (record.totals.weekly or 0) + appliedDelta

    local entryType = appliedDelta > 0 and "manual_award" or "manual_deduct"
    local historyEntry = {
      at = now,
      actor = actorIdentifier,
      type = entryType,
      delta = appliedDelta,
      totals = copyTotals(record),
      reason = payload.reason,
    }

    if payload.metadata then
      historyEntry.metadata = deepCopy(payload.metadata)
    end

    if experience then
      historyEntry.experience = deepCopy(experience)
    end

    self:_applyHistory(record, historyEntry)

    return record, historyEntry
  end, { now = now })

  auditPayload.success = true
  auditPayload.delta = appliedDelta
  auditPayload.limit = commandPayload.limit
  self._audit:log(auditPayload)

  self:_syncOpenCloud(updatedRecord, {
    source = "POINT_ADJUST",
    now = now,
    experience = experience,
  })

  return true, {
    delta = appliedDelta,
    totals = entry and entry.totals or copyTotals(updatedRecord),
    entry = entry,
    limit = commandPayload.limit,
  }
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
