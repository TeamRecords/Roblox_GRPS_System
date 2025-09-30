-- src/roblox/shared/points.lua
-- Deterministic points calculator with caps and anti-abuse.
local Points = {}

local function clamp(x, lo, hi)
	if x < lo then return lo end
	if x > hi then return hi end
	return x
end

-- weights is a table read from policy.points.json
function Points.calculateDelta(event, ctx, weights)
	-- event.type in: "activity","training","operation","ko","wo","recommendation_cmd","recommendation_ccm"
	if event.type == "activity" then
		return weights.activity_tick_5min or 1
	elseif event.type == "training" then
		return weights.training_complete or 15
	elif event.type == "operation" then
		return weights.operation_complete or 25
	elseif event.type == "ko" then
		return weights.ko or 0.25
	elseif event.type == "wo" then
		return weights.wo or -0.1
	elseif event.type == "recommendation_cmd" then
		return weights.recommendation_cmd or 10
	elseif event.type == "recommendation_ccm" then
		return weights.recommendation_ccm or 20
	end
	return 0
end

-- Apply caps given a running total for the period
function Points.applyCaps(currentToday, currentWeek, delta, caps)
	local dcap = caps.daily or math.huge
	local wcap = caps.weekly or math.huge
	local applied = delta

	if currentToday + applied > dcap then
		applied = dcap - currentToday
	end
	if currentWeek + applied > wcap then
		applied = wcap - currentWeek
	end
	return clamp(applied, -math.huge, math.huge)
end

return Points
