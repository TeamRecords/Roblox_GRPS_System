--[[
Permission helpers powered by the policy permissions bundle.

The module exposes a lightweight object that can be constructed with
 a policy table. Actor role extraction is customisable so the helpers
 work with Roblox Instances (using attributes) or plain tables during
 offline tests.
--]]

local Permissions = {}
Permissions.__index = Permissions

local function isInstance(value)
  if typeof then
    local ok, result = pcall(typeof, value)
    if ok then
      return result == "Instance"
    end
  end

  return false
end

local function getAttribute(actor, attribute)
  if isInstance(actor) then
    return actor:GetAttribute(attribute)
  end

  if type(actor) == "table" then
    return actor[attribute]
  end

  return nil
end

local function defaultRoleResolver(actor)
  if actor == nil then
    return nil
  end

  if type(actor) == "string" then
    return actor
  end

  return getAttribute(actor, "RLE_ROLE")
    or getAttribute(actor, "RLE_RANK")
    or getAttribute(actor, "role")
    or getAttribute(actor, "rank")
end

local function clone(tableValue)
  if type(tableValue) ~= "table" then
    return tableValue
  end

  local copy = {}
  for key, value in pairs(tableValue) do
    copy[key] = clone(value)
  end
  return copy
end

function Permissions.new(policy, options)
  assert(type(policy) == "table", "policy table is required")
  options = options or {}

  local roles = (policy.permissions and policy.permissions.roles) or {}
  local instance = setmetatable({}, Permissions)
  instance._roles = clone(roles)
  instance._defaultRole = options.defaultRole or "Guest"
  instance._resolveRole = options.resolveRole or defaultRoleResolver
  return instance
end

function Permissions:describeRole(roleName)
  return self._roles[roleName]
end

function Permissions:resolveRole(actor)
  local roleName = self._resolveRole(actor) or self._defaultRole
  local descriptor = self:describeRole(roleName)
  return descriptor, roleName
end

local function hasFlag(descriptor, key)
  return descriptor and descriptor[key] == true
end

function Permissions:canEarn(actor)
  local descriptor = select(1, self:resolveRole(actor))
  if not descriptor then
    return true
  end

  if descriptor.ignored then
    return false
  end

  if descriptor.canEarn ~= nil then
    return descriptor.canEarn
  end

  return true
end

function Permissions:canWarn(actor)
  local descriptor = select(1, self:resolveRole(actor))
  return hasFlag(descriptor, "canWarn")
end

function Permissions:canBan(actor)
  local descriptor = select(1, self:resolveRole(actor))
  return hasFlag(descriptor, "canBan")
end

function Permissions:isIgnored(actor)
  local descriptor = select(1, self:resolveRole(actor))
  return descriptor and descriptor.ignored == true
end

return Permissions
