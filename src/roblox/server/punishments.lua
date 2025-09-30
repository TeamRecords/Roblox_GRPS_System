--[[
Deterministic punishment tracking for GRPS warning thresholds.

The module never touches Roblox services directly. Instead, callers
provide an adapter implementing `get(key)` and `set(key, value)` so the
same logic can run against DataStores in production or a plain Lua table
in unit tests.
--]]

local Punishments = {}
Punishments.__index = Punishments

local DEFAULT_DATASTORE_NAME = "RLE_GRPS_USERS"

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

local function createTableAdapter(backing)
  local store = backing or {}

  return {
    get = function(_, key)
      return store[key]
    end,
    set = function(_, key, value)
      store[key] = value
    end,
    raw = store,
  }
end

local function buildAdapter(store)
  if store == nil then
    return nil
  end

  if type(store) == "table" then
    if store.get and store.set then
      return store
    end

    if store.GetAsync and store.SetAsync then
      return {
        get = function(_, key)
          return store:GetAsync(key)
        end,
        set = function(_, key, value)
          store:SetAsync(key, value)
        end,
      }
    end
  end

  error("Unsupported store adapter")
end

local function tryCreateDataStore(options)
  if not game or not game.GetService then
    return nil
  end

  local ok, service = pcall(function()
    return game:GetService("DataStoreService")
  end)
  if not ok or not service then
    return nil
  end

  local name = (options and options.dataStoreName) or DEFAULT_DATASTORE_NAME
  local rawStore = service:GetDataStore(name)
  return buildAdapter(rawStore)
end

local function resolveStore(options)
  local adapter = buildAdapter(options and options.store)
  if adapter then
    return adapter
  end

  local dataStoreAdapter = tryCreateDataStore(options)
  if dataStoreAdapter then
    return dataStoreAdapter
  end

  return createTableAdapter()
end

local function now(clock)
  return (clock or os.time)()
end

local function ensureState(state)
  local record = state or {}
  record.warn_count = record.warn_count or 0
  record.warn_history = record.warn_history or {}
  return record
end

function Punishments.new(policy, options)
  assert(type(policy) == "table", "policy table is required")
  options = options or {}

  local instance = setmetatable({}, Punishments)
  instance._policy = policy
  instance._store = resolveStore(options)
  instance._clock = options.clock or os.time
  instance._audit = options.audit
  instance._keyPrefix = options.keyPrefix or "u:"
  return instance
end

function Punishments:_audit(payload)
  if self._audit then
    self._audit(payload)
  end
end

function Punishments:_key(userId)
  return string.format("%s%d", self._keyPrefix, userId)
end

function Punishments:_read(userId)
  local record = self._store:get(self:_key(userId))
  return ensureState(deepCopy(record))
end

function Punishments:_write(userId, record)
  self._store:set(self:_key(userId), deepCopy(record))
end

function Punishments:getState(userId)
  return self:_read(userId)
end

function Punishments:incrementWarn(userId, actorId, reason)
  local record = self:_read(userId)
  record.warn_count = record.warn_count + 1
  table.insert(record.warn_history, {
    at = now(self._clock),
    actor = actorId,
    reason = reason or "unspecified",
  })

  self:_write(userId, record)
  self:_audit({
    action = "WARN_INCREMENT",
    userId = userId,
    actorId = actorId,
    reason = reason,
    count = record.warn_count,
  })

  return record.warn_count
end

function Punishments:evaluate(userId)
  local record = self:_read(userId)
  local punishments = self._policy.punishments or {}
  local severeThreshold = punishments.severe_threshold or math.huge
  local trialThreshold = punishments.trial_threshold or math.huge

  if record.warn_count >= severeThreshold then
    return "SEVERE"
  end

  if record.warn_count >= trialThreshold then
    return "TRIAL"
  end

  return "NONE"
end

function Punishments:applyTrialSuspension(userId, actorId, warnCount)
  local record = self:_read(userId)
  local punishments = self._policy.punishments or {}
  local suspensionDays = punishments.trial_days or 14
  local untilTimestamp = now(self._clock) + suspensionDays * 86400

  record.suspended = true
  record.suspended_until = untilTimestamp
  self:_write(userId, record)

  self:_audit({
    action = "TRIAL_SUSPEND",
    userId = userId,
    actorId = actorId,
    count = warnCount,
    untilTimestamp = untilTimestamp,
  })

  return untilTimestamp
end

function Punishments:applySevereBan(userId, actorId, warnCount)
  local record = self:_read(userId)
  record.banned = true
  record.banned_at = now(self._clock)
  self:_write(userId, record)

  self:_audit({
    action = "SEVERE_BAN",
    userId = userId,
    actorId = actorId,
    count = warnCount,
  })

  return true
end

return Punishments
