-- src/roblox/shared/tests/test_points.lua
local Points = require(script.Parent.Parent.points)

return function(t)
	local weights = {
		activity_tick_5min = 1, training_complete = 15,
		operation_complete = 25, ko=0.25, wo=-0.1,
		recommendation_cmd=10, recommendation_ccm=20
	}
	local caps = { daily=10, weekly=100 }

	t:eq(Points.calculateDelta({type="training"}, {}, weights), 15, "training points")
	local applied = Points.applyCaps(9, 9, 5, caps) -- would exceed daily=10
	t:eq(applied, 1, "daily cap clamps")
end
