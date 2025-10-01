--[[
  Roblox GRPS thin client for the Python automation backend.

  This module intentionally keeps Roblox logic lightweight: it only
  gathers experience data and forwards it to the Python REST API.
  Heavy policy calculations, rank validation, punishments, and
  automation decisions are handled by the backend service.
--]]

local HttpService
if game and game.GetService then
  HttpService = game:GetService("HttpService")
end

local Api = {}
Api.__index = Api

local function ensure(condition, message)
  if not condition then
    error(message, 3)
  end
end

local function coerceBoolean(value)
  if value == nil then
    return nil
  end
  if type(value) == "boolean" then
    return value and "true" or "false"
  end
  if type(value) == "string" then
    local lowered = string.lower(value)
    if lowered == "true" or lowered == "1" or lowered == "yes" then
      return "true"
    end
    return "false"
  end
  if type(value) == "number" then
    return value ~= 0 and "true" or "false"
  end
  return nil
end

function Api.new(options)
  options = options or {}
  ensure(type(options) == "table", "options must be a table")

  local baseUrl = options.baseUrl or options.url or options.endpoint
  ensure(type(baseUrl) == "string" and #baseUrl > 0, "baseUrl is required")

  local http = options.http or HttpService
  ensure(http ~= nil, "HttpService or custom http client required")
  ensure(type(http.RequestAsync) == "function", "http client must expose RequestAsync")

  local jsonEncode = options.jsonEncode or function(payload)
    return http:JSONEncode(payload)
  end
  local jsonDecode = options.jsonDecode or function(text)
    return http:JSONDecode(text)
  end

  local headers = {}
  for key, value in pairs(options.headers or {}) do
    headers[key] = value
  end

  local self = {
    _http = http,
    _baseUrl = string.gsub(baseUrl, "/+$", ""),
    _headers = headers,
    _apiKey = options.apiKey,
    _jsonEncode = jsonEncode,
    _jsonDecode = jsonDecode,
  }

  return setmetatable(self, Api)
end

function Api:_buildHeaders(extra)
  local headers = {
    ["Content-Type"] = "application/json",
    ["Accept"] = "application/json",
  }

  for key, value in pairs(self._headers) do
    headers[key] = value
  end
  if self._apiKey then
    headers["x-grps-api-key"] = self._apiKey
  end
  for key, value in pairs(extra or {}) do
    headers[key] = value
  end

  return headers
end

function Api:_request(method, path, payload, headers)
  local body = nil
  if payload ~= nil then
    if type(payload) == "string" then
      body = payload
    else
      body = self._jsonEncode(payload)
    end
  end

  local requestHeaders = self:_buildHeaders(headers)
  local success, response = pcall(function()
    return self._http:RequestAsync({
      Url = self._baseUrl .. path,
      Method = method,
      Headers = requestHeaders,
      Body = body,
    })
  end)

  if not success then
    return nil, {
      statusCode = 0,
      message = "HTTP request failed",
      error = response,
    }
  end

  if not response.Success then
    local parsed
    if response.Body and response.Body ~= "" then
      local ok, decoded = pcall(function()
        return self._jsonDecode(response.Body)
      end)
      if ok then
        parsed = decoded
      end
    end
    return nil, {
      statusCode = response.StatusCode,
      message = (parsed and (parsed.message or parsed.error)) or response.StatusMessage,
      body = response.Body,
    }
  end

  if response.Body and response.Body ~= "" then
    local ok, decoded = pcall(function()
      return self._jsonDecode(response.Body)
    end)
    if ok then
      return decoded
    end
  end

  return {}
end

local function snapshotHeaders(options)
  local headers = {}
  if options then
    if options.experienceKey then
      headers["x-roblox-experience"] = tostring(options.experienceKey)
    end
    if options.actorUserId then
      headers["x-grps-actor"] = tostring(options.actorUserId)
    end
    local evaluate = coerceBoolean(options.evaluate)
    if evaluate then
      headers["x-grps-evaluate"] = evaluate
    end
    local apply = coerceBoolean(options.apply)
    if apply then
      headers["x-grps-apply"] = apply
    end
  end
  return headers
end

function Api:publishSnapshot(snapshot, options)
  ensure(type(snapshot) == "table", "snapshot must be a table")
  local headers = snapshotHeaders(options)
  local response, err = self:_request("POST", "/roblox/events/player-activity", snapshot, headers)
  if err then
    return nil, err
  end
  return response
end

function Api:getPlayer(userId)
  ensure(userId ~= nil, "userId is required")
  local response, err = self:_request("GET", "/players/" .. tostring(userId), nil, nil)
  if err then
    return nil, err
  end
  return response
end

function Api:requestDecision(payload)
  ensure(type(payload) == "table", "payload must be a table")
  local response, err = self:_request("POST", "/automation/decisions", payload, nil)
  if err then
    return nil, err
  end
  return response
end

function Api:health()
  return self:_request("GET", "/health/live", nil, nil)
end

return Api
