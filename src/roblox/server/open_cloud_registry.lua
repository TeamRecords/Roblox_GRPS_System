--[[
Registry wrapper for managing multiple Open Cloud adapters.

The registry accepts a mix of preconstructed adapters and plain
configuration tables. Each entry is keyed so that API consumers can
resolve a specific Roblox universe/experience without hardcoding
individual adapters throughout the codebase.
--]]

local OpenCloud = require(script.Parent.open_cloud)

local Registry = {}
Registry.__index = Registry

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

local function adapterFromEntry(entry)
  if entry.adapter then
    return entry.adapter
  end

  local options = {
    apiKey = entry.apiKey,
    universeId = entry.universeId,
    datastoreName = entry.datastoreName or entry.datastore,
    scope = entry.scope,
    baseUrl = entry.baseUrl,
    keyFormat = entry.keyFormat,
    httpService = entry.httpService,
  }

  return OpenCloud.new(options)
end

function Registry.new(options)
  options = options or {}

  local instance = setmetatable({}, Registry)
  instance._defaultKey = options.defaultKey or "default"
  instance._entries = {}

  for _, entry in ipairs(options.entries or {}) do
    instance:register(entry)
  end

  return instance
end

function Registry:register(entry)
  assert(type(entry) == "table", "entry table required")
  local key = entry.key or entry.experienceKey or entry.name or "default"
  assert(key ~= nil, "entry key required")

  local adapter = adapterFromEntry(entry)

  self._entries[key] = {
    adapter = adapter,
    key = key,
    universeId = entry.universeId,
    metadata = clone(entry.metadata or {}),
  }

  if entry.default == true then
    self._defaultKey = key
  end

  return self._entries[key]
end

function Registry:list()
  local result = {}
  for key, entry in pairs(self._entries) do
    result[key] = {
      key = key,
      universeId = entry.universeId,
      metadata = clone(entry.metadata or {}),
    }
  end
  return result
end

function Registry:defaultKey()
  return self._defaultKey
end

function Registry:resolve(experience)
  if experience then
    local key = experience.key or experience.experienceKey or experience.id
    if key and self._entries[key] then
      return self._entries[key]
    end

    local universeId = experience.universeId or experience.universeID
    if universeId then
      for _, entry in pairs(self._entries) do
        if entry.universeId and tonumber(entry.universeId) == tonumber(universeId) then
          return entry
        end
      end
    end
  end

  local fallback = self._entries[self._defaultKey]
  if fallback then
    return fallback
  end

  -- final fallback: first registered entry
  for _, entry in pairs(self._entries) do
    return entry
  end

  return nil
end

function Registry:resolveAdapter(experience)
  local entry = self:resolve(experience)
  return entry and entry.adapter or nil
end

return Registry
