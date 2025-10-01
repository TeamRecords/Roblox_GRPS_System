--[[
In-memory and adapter-friendly data store for GRPS player records.

The store keeps deterministic Lua tables so the same logic can run in
Roblox servers (by providing a custom persistence adapter) and in offline
unit tests. Daily and weekly counters reset automatically based on the
current timestamp to mirror Roblox leaderstats behaviour.
--]]

local DataStore = {}
DataStore.__index = DataStore

local SECONDS_PER_DAY = 86400
local SECONDS_PER_WEEK = 604800

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

local function dayIndex(timestamp)
  return math.floor((timestamp or 0) / SECONDS_PER_DAY)
end

local function weekIndex(timestamp)
  return math.floor((timestamp or 0) / SECONDS_PER_WEEK)
end

local function defaultClock()
  return os.time()
end

local function defaultState()
  return {
    players = {},
  }
end

function DataStore.new(options)
  options = options or {}

  local instance = setmetatable({}, DataStore)
  instance._clock = options.clock or defaultClock
  instance._historyLimit = options.historyLimit or 50
  instance._state = options.state and deepCopy(options.state) or defaultState()
  instance._state.players = instance._state.players or {}
  return instance
end

function DataStore:_now(options)
  if options and options.now then
    return options.now
  end
  return self._clock()
end

function DataStore:_ensurePlayer(userId)
  local players = self._state.players
  local record = players[userId]
  if not record then
    record = {
      userId = userId,
      username = nil,
      rank = nil,
      role = nil,
      points = 0,
      kos = 0,
      wos = 0,
      totals = {
        daily = 0,
        weekly = 0,
        dailyIndex = nil,
        weeklyIndex = nil,
      },
      history = {},
      lastKoAt = nil,
      warns = 0,
    }
    players[userId] = record
  end
  return record
end

function DataStore:_normaliseTotals(record, now)
  local totals = record.totals or {}
  totals.dailyIndex = totals.dailyIndex or dayIndex(now)
  totals.weeklyIndex = totals.weeklyIndex or weekIndex(now)

  if totals.dailyIndex ~= dayIndex(now) then
    totals.dailyIndex = dayIndex(now)
    totals.daily = 0
  end

  if totals.weeklyIndex ~= weekIndex(now) then
    totals.weeklyIndex = weekIndex(now)
    totals.weekly = 0
  end

  record.totals = totals
end

function DataStore:_trimHistory(record)
  local history = record.history or {}
  local limit = self._historyLimit
  while #history > limit do
    table.remove(history, 1)
  end
  record.history = history
end

function DataStore:updatePlayer(userId, mutator, options)
  assert(type(mutator) == "function", "mutator must be a function")

  local now = self:_now(options)
  local current = self:_ensurePlayer(userId)
  self:_normaliseTotals(current, now)

  local working = deepCopy(current)
  working.totals = deepCopy(current.totals)
  working.history = deepCopy(current.history)

  local updated, result = mutator(working)
  if updated == nil then
    updated = working
  end

  updated.userId = updated.userId or userId
  updated.totals = updated.totals or { daily = 0, weekly = 0 }
  updated.history = updated.history or {}

  self:_normaliseTotals(updated, now)
  self:_trimHistory(updated)

  self._state.players[userId] = updated

  return deepCopy(updated), result
end

function DataStore:getPlayer(userId)
  local record = self._state.players[userId]
  if not record then
    return nil
  end
  return deepCopy(record)
end

function DataStore:listPlayers()
  local result = {}
  for _, record in pairs(self._state.players) do
    table.insert(result, deepCopy(record))
  end
  return result
end

local function sortByField(players, field)
  table.sort(players, function(left, right)
    local leftValue = left[field] or 0
    local rightValue = right[field] or 0
    if leftValue == rightValue then
      return (left.userId or 0) < (right.userId or 0)
    end
    return leftValue > rightValue
  end)
end

function DataStore:leaderboardTop(limit)
  limit = limit or 25
  local players = self:listPlayers()
  sortByField(players, "points")

  local result = {}
  for index = 1, math.min(limit, #players) do
    local record = players[index]
    result[index] = {
      userId = record.userId,
      username = record.username,
      rank = record.rank,
      points = record.points,
      kos = record.kos,
      wos = record.wos,
    }
  end

  return result
end

local function topMetric(players, field, limit)
  local working = {}
  for _, record in ipairs(players) do
    if (record[field] or 0) > 0 then
      table.insert(working, {
        userId = record.userId,
        username = record.username,
        value = record[field],
      })
    end
  end

  table.sort(working, function(left, right)
    if left.value == right.value then
      return (left.userId or 0) < (right.userId or 0)
    end
    return left.value > right.value
  end)

  local result = {}
  for index = 1, math.min(limit, #working) do
    result[index] = working[index]
  end
  return result
end

function DataStore:records(limit)
  limit = limit or 5
  local players = self:listPlayers()
  return {
    kos = topMetric(players, "kos", limit),
    wos = topMetric(players, "wos", limit),
  }
end

function DataStore:raw()
  return deepCopy(self._state)
end

return DataStore
