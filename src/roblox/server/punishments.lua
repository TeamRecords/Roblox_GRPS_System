-- src/roblox/server/punishments.lua
-- Handles warnings, suspensions, and bans; server-authoritative.
local Punishments = {}
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local store = DataStoreService:GetDataStore("RLE_GRPS_USERS")
local policy -- loaded via shared/policy.lua at runtime

local function now() return os.time() end

function Punishments.init(_policy)
	policy = _policy
end

local function readUser(userId)
	local key = ("u:%d"):format(userId)
	local data = store:GetAsync(key) or {}
	data.warn_count = data.warn_count or 0
	data.banned = data.banned or false
	return key, data
end

local function writeUser(key, data)
	store:SetAsync(key, data)
end

function Punishments.incrementWarn(userId, actorId, reason)
	local key, data = readUser(userId)
	data.warn_count += 1
	writeUser(key, data)
	return data.warn_count
end

function Punishments.applyTrialSuspension(userId, actorId, warn_count)
	local key, data = readUser(userId)
	local days = policy.punishments.trial_days or 14
	data.suspended_until = now() + (days*24*60*60)
	data.suspended = true
	writeUser(key, data)
	return data.suspended_until
end

function Punishments.applySevereBan(userId, actorId, warn_count)
	local key, data = readUser(userId)
	data.banned = true
	writeUser(key, data)
	return true
end

function Punishments.evaluate(userId, actorId)
	local _, data = readUser(userId)
	local punish = policy.punishments
	if data.warn_count >= (punish.severe_threshold or 7) then
		return "SEVERE"
	elseif data.warn_count >= (punish.trial_threshold or 4) then
		return "TRIAL"
	end
	return "NONE"
end

return Punishments
