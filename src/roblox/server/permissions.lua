-- src/roblox/server/permissions.lua
local Permissions = {}

-- In a full build, map real Group ranks to these flags.
local config = {
	canWarnLevels = { CMD=true, CCM=true, LDR=true, MR=true },
	canBanLevels  = { CMD=true, CCM=true, LDR=true },
}

-- Stub: determine actor's level from their rank (replace with real mapping)
local function levelOf(actor)
	return actor:GetAttribute("RLE_LEVEL") or "LR"
end

function Permissions.canWarn(actor)
	local lvl = levelOf(actor)
	return config.canWarnLevels[lvl] == true
end

function Permissions.canBan(actor)
	local lvl = levelOf(actor)
	return config.canBanLevels[lvl] == true
end

return Permissions
