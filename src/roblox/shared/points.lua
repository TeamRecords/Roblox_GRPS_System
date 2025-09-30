--[[
Points utility helpers for the GRPS.

All functions operate on simple Lua tables so they can be executed in
Roblox or during offline testing. Anti-abuse checks are implemented as
pure predicates that accept contextual metadata (such as timestamps or
activity durations) supplied by the caller.
--]]

local Points = {}

local EVENT_WEIGHT_KEYS = {
activity = "activity_tick_5min",
activity_tick_5min = "activity_tick_5min",
training = "training_complete",
training_complete = "training_complete",
operation = "operation_complete",
operation_complete = "operation_complete",
ko = "ko",
wo = "wo",
recommendation_cmd = "recommendation_cmd",
recommendation_ccm = "recommendation_ccm",
}

local function resolveWeightKey(event)
if type(event) ~= "table" then
return nil
end

if event.weightKey then
return event.weightKey
end

return EVENT_WEIGHT_KEYS[event.type]
end

function Points.calculateDelta(event, weights)
weights = weights or {}
local key = resolveWeightKey(event)
if not key then
return 0
end

local weight = weights[key]
if weight == nil then
return 0
end

local magnitude = event.magnitude or 1
return weight * magnitude
end

local function clampDelta(daily, weekly, delta, caps)
caps = caps or {}
local maxDaily = caps.daily or math.huge
local maxWeekly = caps.weekly or math.huge

local dailyHeadroom = maxDaily - (daily or 0)
local weeklyHeadroom = maxWeekly - (weekly or 0)
local headroom = math.min(dailyHeadroom, weeklyHeadroom)

if delta > headroom then
delta = math.max(headroom, 0)
elseif delta < -maxDaily then
delta = -maxDaily
end

return delta
end

function Points.applyCaps(daily, weekly, delta, caps)
return clampDelta(daily or 0, weekly or 0, delta, caps)
end

local function isKoOnCooldown(context, antiAbuse)
local cooldown = antiAbuse.ko_cooldown_seconds
if not cooldown or cooldown <= 0 then
return false
end

local lastKoAt = context and context.lastKoAt
if not lastKoAt then
return false
end

local now = context.now or os.time()
return (now - lastKoAt) < cooldown
end

local function isActivityTooShort(event, context, antiAbuse)
local minimum = antiAbuse.activity_min_seconds
if not minimum or minimum <= 0 then
return false
end

local duration = event and event.duration or context and context.activityDuration or 0
return duration < minimum
end

function Points.enforceAntiAbuse(event, context, antiAbuse)
antiAbuse = antiAbuse or {}

if not event or not event.type then
return true
end

if event.type == "ko" then
if isKoOnCooldown(context, antiAbuse) then
return false, "KO_COOLDOWN"
end
elseif event.type == "activity" or event.type == "activity_tick_5min" then
if isActivityTooShort(event, context, antiAbuse) then
return false, "ACTIVITY_TOO_SHORT"
end
end

return true
end

function Points.resolve(event, totals, policyPoints, context)
policyPoints = policyPoints or {}
totals = totals or {}

local antiAbuse = policyPoints.anti_abuse or {}
local ok, reason = Points.enforceAntiAbuse(event, context, antiAbuse)
if not ok then
return 0, reason
end

local delta = Points.calculateDelta(event, policyPoints.weights)
delta = Points.applyCaps(totals.daily or 0, totals.weekly or 0, delta, policyPoints.caps)

return delta
end

return Points
