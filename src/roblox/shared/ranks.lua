-- src/roblox/shared/ranks.lua
-- Rank utilities: next rank, thresholds, and level mapping.
local Ranks = {}

-- ranks: array ordered from lowest to highest
-- each: { name="", minPoints=0, minTimeDays=0, level="LR", requiredRecs=0 }
function Ranks.levelOf(ranks, name)
	for _, r in ipairs(ranks) do
		if r.name == name then return r.level end
	end
	return nil
end

function Ranks.findIndex(ranks, name)
	for i, r in ipairs(ranks) do
		if r.name == name then return i end
	end
	return nil
end

function Ranks.next(ranks, name)
	local i = Ranks.findIndex(ranks, name)
	if not i then return nil end
	return ranks[i+1] and ranks[i+1].name or nil
end

function Ranks.meetsThresholds(user, targetRank)
	-- user: { points, timeInRankDays, conductScore, recs }
	if user.points < (targetRank.minPoints or 0) then return false, "points" end
	if user.timeInRankDays < (targetRank.minTimeDays or 0) then return false, "time" end
	if targetRank.requiredRecs and (user.recs or 0) < targetRank.requiredRecs then return false, "recs" end
	if targetRank.minConduct and (user.conductScore or 0) < targetRank.minConduct then return false, "conduct" end
	return true
end

return Ranks
