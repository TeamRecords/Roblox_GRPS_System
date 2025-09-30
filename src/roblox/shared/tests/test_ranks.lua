-- src/roblox/shared/tests/test_ranks.lua
local Ranks = require(script.Parent.Parent.ranks)

return function(t)
	local ranks = {
		{ name="Shock Trooper I", minPoints=0, minTimeDays=0, level="LR" },
		{ name="Shock Trooper II", minPoints=50, minTimeDays=2, level="LR" },
		{ name="Volt Specialist I", minPoints=150, minTimeDays=3, level="LR" },
		{ name="Volt Specialist II", minPoints=400, minTimeDays=5, level="MR" },
	}

	t:eq(Ranks.levelOf(ranks, "Volt Specialist II"), "MR", "levelOf")
	t:eq(Ranks.next(ranks, "Shock Trooper I"), "Shock Trooper II", "next rank")

	local user = { points=500, timeInRankDays=10, conductScore=100, recs=0 }
	local ok = select(1, Ranks.meetsThresholds(user, ranks[4]))
	t:eq(ok, true, "meets thresholds")
end
