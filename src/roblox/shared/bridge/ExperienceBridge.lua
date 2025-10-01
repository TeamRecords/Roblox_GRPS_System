--[[
HTTP bridge used by auxiliary experiences to push data into the GRPS backend.

Place this ModuleScript next to `ExperienceConfig` and require it from the
server bootstrapper. The bridge is intentionally stateless so that it can be
shared across multiple scripts or invoked from command consoles.
--]]

local HttpService = game:GetService("HttpService")

local Bridge = {}
Bridge.__index = Bridge

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

local function buildRankLookup(list)
  local lookup = {}
  for _, value in ipairs(list or {}) do
    lookup[value] = true
  end
  return lookup
end

function Bridge.configure(config)
  Bridge._config = clone(config or {})
  Bridge._httpService = Bridge._config.httpService or HttpService
  Bridge._rankLookup = buildRankLookup(Bridge._config.commandRanks)

  for _, rank in ipairs(Bridge._config.centralCommandRanks or {}) do
    Bridge._rankLookup[rank] = true
  end
end

function Bridge.getExperienceContext()
  local config = Bridge._config or {}
  local context = {
    key = config.experienceKey,
    universeId = config.universeId or game.GameId,
    placeId = game.PlaceId,
    server = game.JobId,
  }

  if config.name then
    context.name = config.name
  end

  return context
end

local function resolveEndpoint(key)
  local config = Bridge._config
  assert(config, "Bridge not configured")

  local endpoints = config.endpoints or {}
  local template = endpoints[key]
  assert(type(template) == "string" and template ~= "", "endpoint template missing for " .. tostring(key))

  local experienceKey = assert(config.experienceKey, "experienceKey required in config")
  return (template:gsub("{experienceKey}", experienceKey))
end

local function request(endpointKey, payload)
  local config = Bridge._config
  assert(config, "Bridge not configured")

  local baseUrl = assert(config.automationBaseUrl, "automationBaseUrl missing")
  local endpoint = resolveEndpoint(endpointKey)
  local url = baseUrl .. endpoint

  local headers = clone(config.headers or {})
  headers["Content-Type"] = headers["Content-Type"] or "application/json"

  if config.apiKey then
    local headerName = config.apiKeyHeader or "x-api-key"
    headers[headerName] = config.apiKey
  end

  local body = payload
  if type(body) == "table" then
    body = Bridge._httpService:JSONEncode(body)
  end

  local ok, response = pcall(function()
    return Bridge._httpService:RequestAsync({
      Url = url,
      Method = "POST",
      Headers = headers,
      Body = body,
    })
  end)

  if not ok then
    warn("[GRPSBridge] Request failed:", response)
    return false, tostring(response)
  end

  if response.Success ~= true then
    local message = response.StatusMessage or response.StatusCode
    warn("[GRPSBridge] Non-success response", message)
    return false, message, response
  end

  if response.Body and response.Body ~= "" then
    local decodeOk, decoded = pcall(function()
      return Bridge._httpService:JSONDecode(response.Body)
    end)
    if decodeOk then
      return true, decoded, response
    end
  end

  return true, nil, response
end

local function leaderstatValue(player, name)
  local leaderstats = player:FindFirstChild("leaderstats")
  if not leaderstats then
    return nil
  end

  local object = leaderstats:FindFirstChild(name)
  if not object then
    return nil
  end

  local ok, value = pcall(function()
    return object.Value
  end)

  if ok then
    return value
  end

  return nil
end

function Bridge.describePlayer(player)
  return {
    userId = player.UserId,
    username = player.Name,
    displayName = player.DisplayName,
    kos = leaderstatValue(player, "KOs") or 0,
    wos = leaderstatValue(player, "WOs") or 0,
  }
end

function Bridge.syncPlayers(players)
  if not players or #players == 0 then
    return true
  end

  local records = {}
  for _, player in ipairs(players) do
    table.insert(records, Bridge.describePlayer(player))
  end

  local payload = {
    experience = Bridge.getExperienceContext(),
    players = records,
  }

  local ok, response = request("sync", payload)
  if not ok then
    return false, response
  end

  return true, response
end

local function describeActor(player)
  if not player then
    return nil
  end

  local descriptor = Bridge.describePlayer(player)
  descriptor.role = player:GetAttribute("RLE_ROLE") or player:GetAttribute("RLE_RANK")
  return descriptor
end

local function buildTargetDescriptor(target)
  if typeof(target) == "Instance" then
    return Bridge.describePlayer(target)
  elseif type(target) == "table" then
    return clone(target)
  end

  return nil
end

function Bridge.adjustPoints(options)
  assert(type(options) == "table", "options table required")

  local payload = {
    experience = Bridge.getExperienceContext(),
    actor = describeActor(options.actor),
    target = buildTargetDescriptor(options.target),
    amount = options.amount,
    reason = options.reason,
    metadata = options.metadata,
  }

  return request("adjust", payload)
end

function Bridge.warn(options)
  assert(type(options) == "table", "options table required")

  local payload = {
    experience = Bridge.getExperienceContext(),
    actor = describeActor(options.actor),
    target = buildTargetDescriptor(options.target),
    reason = options.reason,
    metadata = options.metadata,
  }

  return request("warn", payload)
end

local function hasRoleMatch(player)
  local config = Bridge._config or {}
  local roles = config.allowedRoles
  if not roles or #roles == 0 then
    return false
  end

  local attributeName = config.roleAttribute or "RLE_ROLE"
  local roleValue = player:GetAttribute(attributeName) or player:GetAttribute("RLE_RANK")
  if type(roleValue) ~= "string" then
    return false
  end

  local lower = string.lower(roleValue)
  for _, allowed in ipairs(roles) do
    if string.lower(allowed) == lower then
      return true
    end
  end

  return false
end

function Bridge.isAuthorised(actor)
  local config = Bridge._config
  if not config then
    return false
  end

  if config.groupId then
    local ok, rank = pcall(function()
      return actor:GetRankInGroup(config.groupId)
    end)
    if ok and Bridge._rankLookup[rank] then
      return true
    end
  end

  return hasRoleMatch(actor)
end

function Bridge.getMaxAdjustment()
  local config = Bridge._config or {}
  return config.maxAdjustment or 25
end

function Bridge.clampAdjustment(amount)
  local limit = Bridge.getMaxAdjustment()
  if math.abs(amount) > limit then
    if amount > 0 then
      return limit
    else
      return -limit
    end
  end
  return amount
end

return Bridge
