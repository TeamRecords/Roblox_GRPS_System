--[[
Structured JSONL audit logger for GRPS server modules.

The logger is deterministic and can operate fully offline. Callers can
provide a custom writer (for example, Roblox DataStore or HttpService
endpoints) or rely on the default stdout sink. Each log line is emitted
as a single JSON object so that downstream pipelines can stream the
output directly into storage or analytics tooling.
--]]

local Audit = {}
Audit.__index = Audit

local DEFAULT_SOURCE = "GRPS"

local function isArray(tableValue)
  local count = 0
  for key in pairs(tableValue) do
    if type(key) ~= "number" then
      return false
    end
    count = count + 1
  end

  if count == 0 then
    return true
  end

  for index = 1, count do
    if tableValue[index] == nil then
      return false
    end
  end

  return true
end

local function escapeString(value)
  local replacements = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
  }

  return value:gsub("[\\\"\b\f\n\r\t]", replacements)
end

local function encodeJson(value)
  local valueType = type(value)

  if valueType == "nil" then
    return "null"
  elseif valueType == "number" then
    return tostring(value)
  elseif valueType == "boolean" then
    return value and "true" or "false"
  elseif valueType == "string" then
    return string.format('"%s"', escapeString(value))
  elseif valueType == "table" then
    if isArray(value) then
      local buffer = {}
      for index = 1, #value do
        buffer[index] = encodeJson(value[index])
      end
      return string.format('[%s]', table.concat(buffer, ","))
    end

    local keys = {}
    for key in pairs(value) do
      table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
      return tostring(a) < tostring(b)
    end)

    local buffer = {}
    for index, key in ipairs(keys) do
      buffer[index] = string.format('"%s":%s', escapeString(tostring(key)), encodeJson(value[key]))
    end
    return string.format('{%s}', table.concat(buffer, ","))
  end

  error("Unsupported JSON type: " .. valueType)
end

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

local function defaultWriter(line)
  print(line)
end

function Audit.new(options)
  options = options or {}

  local instance = setmetatable({}, Audit)
  instance._clock = options.clock or os.time
  instance._source = options.source or DEFAULT_SOURCE
  instance._writer = options.writer or defaultWriter
  instance._static = deepCopy(options.static or {})
  return instance
end

function Audit:_now()
  return self._clock()
end

function Audit:_prepare(event)
  assert(type(event) == "table", "event payload must be a table")

  local payload = {}
  for key, value in pairs(self._static) do
    payload[key] = deepCopy(value)
  end

  for key, value in pairs(event) do
    payload[key] = deepCopy(value)
  end

  payload.at = payload.at or self:_now()
  payload.source = payload.source or self._source

  return payload
end

function Audit:log(event)
  local payload = self:_prepare(event)
  local line = encodeJson(payload)
  self._writer(line)
  return line
end

function Audit.encode(value)
  return encodeJson(value)
end

return Audit
