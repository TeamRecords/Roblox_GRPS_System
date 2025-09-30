-- src/roblox/server/commands.lua
-- Slash-style commands; wire to TextChatService or custom UI.
local Commands = {}
local Permissions = require(script.Parent.permissions)
local Punishments = require(script.Parent.punishments)
local Policy = require(script.Parent.Parent.shared.policy)

local policy

function Commands.init()
	policy = Policy.load()
	Punishments.init(policy)
end

local function respond(player, msg)
	-- Replace with proper UI hook
	print(("[CMD RESP:%s] %s"):format(player and player.Name or "server", msg))
end

function Commands.warn(actor, targetUserId, reason)
	if not Permissions.canWarn(actor) then
		return respond(actor, "You do not have permission to warn.")
	end
	local count = Punishments.incrementWarn(targetUserId, actor.UserId, reason or "unspecified")
	local state = Punishments.evaluate(targetUserId, actor.UserId)
	if state == "TRIAL" then
		Punishments.applyTrialSuspension(targetUserId, actor.UserId, count)
		respond(actor, ("User %d moved to Suspended (Punishment_Trial). Count=%d"):format(targetUserId, count))
	elseif state == "SEVERE" then
		Punishments.applySevereBan(targetUserId, actor.UserId, count)
		respond(actor, ("User %d banned (Punishment_Severe). Count=%d"):format(targetUserId, count))
	else
		respond(actor, ("Warn added. Count=%d"):format(count))
	end
end

return Commands
