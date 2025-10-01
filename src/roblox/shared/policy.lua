--[[
Robloxian Lightning Empire — GRPS policy module

Provides deterministic access to the canonical policy bundle used by
the Group Rank Point System. The module keeps a Lua representation of
the JSON policies shipped in `/config` and exposes helpers for looking
up ranks, permissions, and point weighting metadata without touching
Roblox services. All functions are pure and side-effect free so that
they can be unit tested from plain Lua.
--]]

local Policy = {}
Policy.__index = Policy

local DEFAULT_POLICY = {
points = {
weights = {
activity_tick_5min = 1,
training_complete = 15,
operation_complete = 25,
ko = 0.25,
wo = -0.1,
recommendation_cmd = 10,
recommendation_ccm = 20,
},
caps = {
daily = 500,
weekly = 2500,
},
anti_abuse = {
ko_cooldown_seconds = 30,
activity_min_seconds = 300,
},
},
  ranks = {
    { name = "Suspended", minPoints = 0, minTimeDays = 0, level = "Trial", isPunishment = true },
    { name = "Initiate", minPoints = 0, minTimeDays = 0, level = "LR" },
    { name = "Shock Trooper I", minPoints = 50, minTimeDays = 1, level = "LR" },
    { name = "Shock Trooper II", minPoints = 150, minTimeDays = 2, level = "LR" },
    { name = "Volt Specialist I", minPoints = 300, minTimeDays = 3, level = "LR" },
    { name = "Volt Specialist II", minPoints = 500, minTimeDays = 4, level = "MR" },
    { name = "Storm Corporal I", minPoints = 750, minTimeDays = 5, level = "MR" },
    { name = "Storm Corporal II", minPoints = 1000, minTimeDays = 7, level = "MR" },
    { name = "Thunder Sergeant I", minPoints = 1400, minTimeDays = 9, level = "MR" },
    { name = "Thunder Sergeant II", minPoints = 1800, minTimeDays = 11, level = "MR" },
    { name = "Arc Lieutenant I", minPoints = 2200, minTimeDays = 14, level = "MR" },
    { name = "Arc Lieutenant II", minPoints = 2600, minTimeDays = 16, level = "MR" },
    { name = "Captain I", minPoints = 3000, minTimeDays = 18, level = "D&I" },
    { name = "Captain II", minPoints = 3200, minTimeDays = 21, level = "D&I" },
    { name = "Envoy", minPoints = 3600, minTimeDays = 24, level = "CMD", privileged = true },
    { name = "Ambassador", minPoints = 4000, minTimeDays = 28, level = "CMD", privileged = true },
    { name = "Tempest Major", minPoints = 4500, minTimeDays = 32, level = "CMD", privileged = true },
    { name = "Electro Colonel", minPoints = 5500, minTimeDays = 40, level = "CMD", privileged = true },
    { name = "Brigadier General", minPoints = 7000, minTimeDays = 50, level = "CCM", privileged = true },
    { name = "Stormmarshal", minPoints = 8500, minTimeDays = 60, level = "CCM", privileged = true },
    { name = "Supreme Admirals", minPoints = 10000, minTimeDays = 75, level = "CCM", privileged = true },
    { name = "Supreme Command", minPoints = 12500, minTimeDays = 90, level = "LDR", privileged = true },
    { name = "Supreme Council", minPoints = 15000, minTimeDays = 110, level = "LDR", privileged = true },
    { name = "Imperator", minPoints = 20000, minTimeDays = 130, level = "LDR", privileged = true },
  },
punishments = {
trial_threshold = 4,
severe_threshold = 7,
trial_days = 14,
trial_lock_promotion = true,
},
permissions = {
roles = {
["Guest"] = { level = "N/A", ignored = true },
    ["Initiate"] = { level = "LR", canEarn = true },
    ["Suspended"] = { level = "Trial", canEarn = false, locked = true },
    ["Shock Trooper I"] = { level = "LR", canEarn = true },
    ["Shock Trooper II"] = { level = "LR", canEarn = true },
    ["Volt Specialist I"] = { level = "LR", canEarn = true },
    ["Volt Specialist II"] = { level = "MR", canEarn = true },
    ["Storm Corporal I"] = { level = "MR", canEarn = true },
    ["Storm Corporal II"] = { level = "MR", canEarn = true },
    ["Thunder Sergeant I"] = { level = "MR", canEarn = true },
    ["Thunder Sergeant II"] = { level = "MR", canEarn = true },
    ["Arc Lieutenant I"] = { level = "MR", canEarn = true },
    ["Arc Lieutenant II"] = { level = "MR", canEarn = true },
    ["Captain I"] = { level = "D&I", canEarn = true },
    ["Captain II"] = { level = "D&I", canEarn = true },
    ["Envoy"] = { level = "CMD", canWarn = true, canAdjust = true },
    ["Ambassador"] = { level = "CMD", canWarn = true, canAdjust = true },
    ["Tempest Major"] = { level = "CMD", canWarn = true, canAdjust = true },
    ["Electro Colonel"] = { level = "CMD", canWarn = true, canAdjust = true, canBan = true },
    ["Brigadier General"] = { level = "CCM", canWarn = true, canAdjust = true, canBan = true },
    ["Stormmarshal"] = { level = "CCM", canWarn = true, canAdjust = true, canBan = true },
    ["Supreme Admirals"] = { level = "CCM", canWarn = true, canAdjust = true, canBan = true },
    ["Supreme Command"] = { level = "LDR", canWarn = true, canAdjust = true, canBan = true },
    ["Supreme Council"] = { level = "LDR", canWarn = true, canAdjust = true, canBan = true },
    ["Imperator"] = { level = "LDR", canWarn = true, canAdjust = true, canBan = true },
  },
},
}

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

local function deepMerge(base, overrides)
local result = deepCopy(base)

for key, value in pairs(overrides or {}) do
if type(value) == "table" and type(result[key]) == "table" then
result[key] = deepMerge(result[key], value)
else
result[key] = deepCopy(value)
end
end

return result
end

local function normaliseRanks(ranks)
table.sort(ranks, function(left, right)
return (left.minPoints or 0) < (right.minPoints or 0)
end)

local byName = {}
for index, rank in ipairs(ranks) do
local copy = deepCopy(rank)
copy.index = index
byName[copy.name] = copy
ranks[index] = copy
end

return ranks, byName
end

local function normalisePermissions(permissions)
local roles = {}
for roleName, descriptor in pairs(permissions.roles or {}) do
roles[roleName] = deepCopy(descriptor)
end

return { roles = roles }
end

local function fromTable(policyTable)
assert(type(policyTable) == "table", "policyTable must be a table")

local bundle = {
points = deepMerge(DEFAULT_POLICY.points, policyTable.points or {}),
punishments = deepMerge(DEFAULT_POLICY.punishments, policyTable.punishments or {}),
}

local ranks = policyTable.ranks and deepCopy(policyTable.ranks) or deepCopy(DEFAULT_POLICY.ranks)
bundle.ranks, bundle.ranksByName = normaliseRanks(ranks)
bundle.permissions = normalisePermissions(policyTable.permissions or DEFAULT_POLICY.permissions)

return bundle
end

function Policy.load(options)
options = options or {}
local source = options.source or DEFAULT_POLICY

local resolved
if type(source) == "function" then
resolved = source()
else
resolved = source
end

if options.overrides then
resolved = deepMerge(resolved, options.overrides)
end

return fromTable(resolved)
end

function Policy.getRank(policy, rankName)
return policy.ranksByName and policy.ranksByName[rankName]
end

function Policy.getNextRank(policy, rankName)
local current = Policy.getRank(policy, rankName)
if not current then
return nil
end
return policy.ranks[current.index + 1]
end

function Policy.getPermissionDescriptor(policy, roleName)
local permissions = policy.permissions and policy.permissions.roles
if not permissions then
return nil
end
return permissions[roleName]
end

function Policy.deepCopy(policy)
return deepCopy(policy)
end

return Policy
