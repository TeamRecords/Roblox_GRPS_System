-- src/roblox/shared/policy.lua
local Policy = {}
local HttpService = game:GetService("HttpService")
local policyCache

function Policy.load()
	if policyCache then return policyCache end
	-- In practice, read JSON assets inserted into the game or via remote config.
	policyCache = {
		punishments = {
			trial_threshold = 4,
			severe_threshold = 7,
			trial_days = 14,
			trial_lock_promotion = true
		}
	}
	return policyCache
end

return Policy
