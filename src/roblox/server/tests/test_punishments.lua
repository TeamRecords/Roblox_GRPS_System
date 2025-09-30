-- src/roblox/server/tests/test_punishments.lua
local Punishments = require(script.Parent.Parent.punishments)
local Policy = require(script.Parent.Parent.Parent.shared.policy)

return function(t)
	local policy = Policy.load()
	Punishments.init(policy)
	
	-- Simulate warnings
	local uid = 12345
	local aid = 999
	
	-- reset is omitted; assume fresh user.
	for i=1,4 do
		Punishments.incrementWarn(uid, aid, "test")
	end
	local st = Punishments.evaluate(uid, aid)
	t:eq(st, "TRIAL", "Warn>=4 triggers trial")
end
