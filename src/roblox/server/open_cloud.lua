--[[
Roblox Open Cloud adapter for the GRPS server.

The adapter wraps the official Roblox Creator Hub Open Cloud Data Store
endpoints so that GRPS can push authoritative player snapshots to a
standard data store directly from server scripts. All requests are made
through `HttpService:RequestAsync` and respect the API key and universe
identifier documented at https://create.roblox.com/docs/cloud.

Usage:

```
local OpenCloud = require(path.to.open_cloud)
local adapter = OpenCloud.new({
  apiKey = "rbx-oc-...",
  universeId = 1234567890,
  datastoreName = "GRPS_Points",
})

adapter:writePlayerSnapshot({ userId = 1, points = 10 })
```

The module is dependency-injected friendly so offline tests can supply a
mock HttpService implementation.
--]]

local DEFAULT_BASE_URL = "https://apis.roblox.com"

local function defaultHttpService()
  if typeof and typeof(game) == "Instance" then
    local ok, service = pcall(function()
      return game:GetService("HttpService")
    end)
    if ok then
      return service
    end
  end

  error("HttpService is required; supply via options.httpService")
end

local function clone(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, inner in pairs(value) do
    copy[key] = clone(inner)
  end
  return copy
end

local OpenCloud = {}
OpenCloud.__index = OpenCloud

function OpenCloud.new(options)
  assert(type(options) == "table", "options table required")

  local httpService = options.httpService or defaultHttpService()

  local instance = setmetatable({}, OpenCloud)
  instance._httpService = httpService
  instance._apiKey = assert(options.apiKey, "apiKey required")
  instance._universeId = assert(options.universeId, "universeId required")
  instance._datastoreName = assert(options.datastoreName, "datastoreName required")
  instance._scope = options.scope or "global"
  instance._baseUrl = options.baseUrl or DEFAULT_BASE_URL
  instance._keyFormat = options.keyFormat or "player:{userId}"
  return instance
end

function OpenCloud:_basePath()
  return string.format(
    "/datastores/v1/universes/%s/standard-datastores/%s",
    tostring(self._universeId),
    tostring(self._datastoreName)
  )
end

function OpenCloud:_formatKey(userId)
  local format = self._keyFormat
  if string.find(format, "{userId}", 1, true) then
    return (string.gsub(format, "{userId}", tostring(userId)))
  end
  if string.find(format, "%%", 1, true) then
    return string.format(format, userId)
  end
  return format .. tostring(userId)
end

function OpenCloud:_queryString(params)
  local httpService = self._httpService
  local parts = {}
  for key, value in pairs(params or {}) do
    if value ~= nil then
      local encodedKey = httpService:UrlEncode(tostring(key))
      local encodedValue = httpService:UrlEncode(tostring(value))
      table.insert(parts, encodedKey .. "=" .. encodedValue)
    end
  end

  if #parts == 0 then
    return ""
  end

  return "?" .. table.concat(parts, "&")
end

local function mergeHeaders(base, extras)
  local headers = {}
  for key, value in pairs(base) do
    headers[key] = value
  end
  for key, value in pairs(extras or {}) do
    if value ~= nil then
      headers[key] = value
    end
  end
  return headers
end

function OpenCloud:_request(method, path, queryParams, body, extraHeaders)
  local httpService = self._httpService
  local url = self._baseUrl .. path .. self:_queryString(queryParams)

  local headers = mergeHeaders({
    ["x-api-key"] = self._apiKey,
  }, extraHeaders)

  local requestBody = body
  if type(requestBody) == "table" then
    requestBody = httpService:JSONEncode(requestBody)
    headers["Content-Type"] = headers["Content-Type"] or "application/json"
  elseif requestBody == nil then
    requestBody = nil
  end

  local ok, response = pcall(function()
    return httpService:RequestAsync({
      Url = url,
      Method = method,
      Headers = headers,
      Body = requestBody,
    })
  end)

  if not ok then
    return false, response
  end

  if response.Success ~= true then
    local message = response.StatusMessage or response.StatusCode
    return false, message, response
  end

  local decoded
  if response.Body and response.Body ~= "" then
    local decodeOk, payload = pcall(function()
      return httpService:JSONDecode(response.Body)
    end)
    decoded = decodeOk and payload or response.Body
  end

  return true, decoded, response
end

function OpenCloud:listEntries(options)
  options = options or {}

  local query = {
    scope = options.scope or self._scope,
    prefix = options.prefix,
    limit = options.limit,
    cursor = options.cursor,
  }

  return self:_request(
    "GET",
    self:_basePath() .. "/entries",
    query
  )
end

function OpenCloud:getEntry(key, options)
  assert(type(key) == "string" and key ~= "", "key string required")
  options = options or {}

  local query = {
    scope = options.scope or self._scope,
    key = key,
  }

  return self:_request(
    "GET",
    self:_basePath() .. "/entries/entry",
    query
  )
end

function OpenCloud:writeEntry(key, payload, options)
  assert(type(key) == "string" and key ~= "", "key string required")
  options = options or {}

  local headers = {}
  if options.attributes then
    headers["roblox-entry-attributes"] = self._httpService:JSONEncode(options.attributes)
  end
  if options.userIds then
    headers["roblox-entry-userids"] = table.concat(options.userIds, ",")
  end
  if options.matchVersion then
    headers["roblox-entry-version"] = tostring(options.matchVersion)
  end

  local query = {
    scope = options.scope or self._scope,
    key = key,
  }

  return self:_request(
    "POST",
    self:_basePath() .. "/entries/entry",
    query,
    payload,
    headers
  )
end

local function trimHistory(history)
  if type(history) ~= "table" then
    return history
  end

  local copy = {}
  for index, entry in ipairs(history) do
    copy[index] = clone(entry)
  end
  return copy
end

function OpenCloud:writePlayerSnapshot(record, options)
  assert(type(record) == "table", "record table required")
  assert(record.userId, "record.userId required")

  options = options or {}
  local now = options.now or os.time()

  local payload = {
    userId = record.userId,
    username = record.username,
    rank = record.rank,
    points = record.points,
    kos = record.kos,
    wos = record.wos,
    warns = record.warns,
    totals = clone(record.totals or {}),
    history = trimHistory(record.history or {}),
    updatedAt = now,
  }

  local attributes = {
    points = record.points,
    kos = record.kos,
    wos = record.wos,
    rank = record.rank,
  }

  return self:writeEntry(
    self:_formatKey(record.userId),
    payload,
    {
      scope = options.scope,
      userIds = { record.userId },
      attributes = attributes,
      matchVersion = options.matchVersion,
    }
  )
end

return OpenCloud

