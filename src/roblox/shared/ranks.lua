--[[
Rank utilities for GRPS rank progression.

The helpers operate on arrays of rank descriptors as produced by the
policy module. Threshold evaluation is kept deterministic and returns
detailed failure reasons to make automation straightforward.
--]]

local Ranks = {}

local FAILURE_REASONS = {
points = "points",
time = "time",
recommendations = "recs",
conduct = "conduct",
permitted = "permitted",
}

local function copyDescriptor(rank)
local clone = {}
for key, value in pairs(rank) do
clone[key] = value
end
return clone
end

function Ranks.find(ranks, name)
if not ranks or not name then
return nil
end

for _, descriptor in ipairs(ranks) do
if descriptor.name == name then
return descriptor
end
end

return nil
end

function Ranks.indexOf(ranks, name)
if not ranks then
return nil
end

for index, descriptor in ipairs(ranks) do
if descriptor.name == name then
return index
end
end

return nil
end

function Ranks.next(ranks, name)
local index = Ranks.indexOf(ranks, name)
if not index then
return nil
end

return ranks[index + 1]
end

function Ranks.previous(ranks, name)
local index = Ranks.indexOf(ranks, name)
if not index or index <= 1 then
return nil
end

return ranks[index - 1]
end

local function requiredCount(rank)
return rank and rank.requiredRecs or rank and rank.requiredRecommendations
end

local function meetsPoints(user, targetRank)
local current = user.points or 0
local requirement = targetRank.minPoints or 0
if current < requirement then
return false, FAILURE_REASONS.points
end
return true
end

local function meetsTime(user, targetRank)
local current = user.timeInRankDays or 0
local requirement = targetRank.minTimeDays or 0
if current < requirement then
return false, FAILURE_REASONS.time
end
return true
end

local function meetsRecommendations(user, targetRank)
local requirement = requiredCount(targetRank)
if not requirement or requirement <= 0 then
return true
end

local current = user.recs or user.recommendations or 0
if current < requirement then
return false, FAILURE_REASONS.recommendations
end
return true
end

local function meetsConduct(user, targetRank)
local requirement = targetRank.minConduct
if not requirement then
return true
end

local current = user.conductScore or user.conduct or 0
if current < requirement then
return false, FAILURE_REASONS.conduct
end
return true
end

function Ranks.meetsThresholds(user, targetRank)
assert(type(user) == "table", "user must be a table")
assert(type(targetRank) == "table", "targetRank must be a table")

local checks = { meetsPoints, meetsTime, meetsRecommendations, meetsConduct }

for _, predicate in ipairs(checks) do
local ok, reason = predicate(user, targetRank)
if not ok then
return false, reason
end
end

return true
end

function Ranks.buildIndex(ranks)
local byName = {}
for _, descriptor in ipairs(ranks or {}) do
byName[descriptor.name] = copyDescriptor(descriptor)
end
return byName
end

function Ranks.isPromotionPermitted(user, policy)
if not policy or not policy.punishments then
return true
end

local punishments = policy.punishments
if not punishments.trial_lock_promotion then
return true
end

if user.suspended_until and user.suspended_until > (user.now or os.time()) then
return false, FAILURE_REASONS.permitted
end

return true
end

return Ranks
