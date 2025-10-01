--[[
Server bootstrapper used by auxiliary experiences to synchronise with the
GRPS backend. Place this Script inside `ServerScriptService/GRPSBridge` and
ensure the sibling ModuleScripts `ExperienceConfig` and `ExperienceBridge`
are present.

The bootstrapper performs three responsibilities:
1. Validates and populates leaderstats (Username, KOs, WOs) for every player.
2. Batches stat changes and forwards them to the automation API.
3. Exposes lightweight chat commands for Command and Central Command members
   to award, deduct, or warn players with a reason.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bridgeModule = script.Parent:WaitForChild("ExperienceBridge")
local configModule = script.Parent:WaitForChild("ExperienceConfig")

local Bridge = require(bridgeModule)
local Config = require(configModule)
Bridge.configure(Config)

local SYNC_INTERVAL = Config.syncIntervalSeconds or 30
local MESSAGE_EVENT_NAME = "GRPSBridgeMessage"

local messageEvent = ReplicatedStorage:FindFirstChild(MESSAGE_EVENT_NAME)
if not messageEvent then
  messageEvent = Instance.new("RemoteEvent")
  messageEvent.Name = MESSAGE_EVENT_NAME
  messageEvent.Parent = ReplicatedStorage
end

local function sendMessage(player, message)
  if player and player.Parent then
    messageEvent:FireClient(player, message)
  end
end

local function ensureLeaderstats(player)
  local stats = player:FindFirstChild("leaderstats")
  if not stats then
    stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player
  end

  local usernameValue = stats:FindFirstChild("Username")
  if not usernameValue then
    usernameValue = Instance.new("StringValue")
    usernameValue.Name = "Username"
    usernameValue.Parent = stats
  end
  usernameValue.Value = player.Name

  local koValue = stats:FindFirstChild("KOs")
  if not koValue then
    koValue = Instance.new("IntValue")
    koValue.Name = "KOs"
    koValue.Parent = stats
  end

  local woValue = stats:FindFirstChild("WOs")
  if not woValue then
    woValue = Instance.new("IntValue")
    woValue.Name = "WOs"
    woValue.Parent = stats
  end

  return stats, koValue, woValue
end

local pendingSync = {}
local connections = {}

local function queueSync(player)
  pendingSync[player.UserId] = player
end

local function disconnectPlayer(player)
  local userId = player.UserId
  if connections[userId] then
    for _, conn in ipairs(connections[userId]) do
      conn:Disconnect()
    end
  end
  connections[userId] = nil
  pendingSync[userId] = nil
end

local function attachListeners(player, stats, koValue, woValue)
  connections[player.UserId] = connections[player.UserId] or {}

  local function watch(object)
    if not object then
      return
    end

    local conn = object:GetPropertyChangedSignal("Value"):Connect(function()
      queueSync(player)
    end)
    table.insert(connections[player.UserId], conn)
  end

  watch(koValue)
  watch(woValue)

  local usernameObj = stats:FindFirstChild("Username")
  if usernameObj then
    table.insert(connections[player.UserId], usernameObj:GetPropertyChangedSignal("Value"):Connect(function()
      queueSync(player)
    end))
  end
end

local function syncLoop()
  while true do
    task.wait(math.max(SYNC_INTERVAL, 1))
    local toSync = {}
    for userId, player in pairs(pendingSync) do
      if player.Parent then
        table.insert(toSync, player)
      end
      pendingSync[userId] = nil
    end

    if #toSync > 0 then
      local ok, response = Bridge.syncPlayers(toSync)
      if not ok then
        warn("[GRPSBridge] Failed to sync players:", response)
      end
    end
  end
end

task.spawn(syncLoop)

local function resolveTarget(name)
  if not name or name == "" then
    return nil
  end

  local player = Players:FindFirstChild(name)
  if player then
    return player
  end

  local lower = name:lower()
  for _, candidate in ipairs(Players:GetPlayers()) do
    if candidate.Name:lower() == lower then
      return candidate
    end
  end

  local ok, userId = pcall(function()
    return Players:GetUserIdFromNameAsync(name)
  end)

  if not ok then
    return nil, "USER_NOT_FOUND"
  end

  return {
    userId = userId,
    username = name,
  }
end

local function parseCommand(message)
  if type(message) ~= "string" then
    return nil
  end

  if not message:lower():match("^!grps") then
    return nil
  end

  local parts = {}
  for token in string.gmatch(message, "[^%s]+") do
    table.insert(parts, token)
  end

  if #parts < 3 then
    return nil, "USAGE"
  end

  local action = parts[2]:lower()
  local targetName = parts[3]

  if action == "warn" then
    if #parts < 4 then
      return nil, "REASON_REQUIRED"
    end
    local reason = table.concat(parts, " ", 4)
    return {
      type = "warn",
      target = targetName,
      reason = reason,
    }
  elseif action == "add" or action == "sub" or action == "deduct" then
    if #parts < 5 then
      return nil, "USAGE"
    end
    local rawAmount = tonumber(parts[4]) or 0
    local amount = math.abs(rawAmount)
    if action ~= "add" then
      amount = -amount
    end
    local reason = table.concat(parts, " ", 5)
    if reason == "" then
      return nil, "REASON_REQUIRED"
    end
    return {
      type = "adjust",
      target = targetName,
      amount = amount,
      reason = reason,
    }
  end

  return nil, "UNKNOWN_ACTION"
end

local function sanitizeReason(reason)
  if type(reason) ~= "string" then
    return ""
  end

  reason = reason:gsub("^%s+", "")
  if #reason > 250 then
    return reason:sub(1, 250)
  end

  return reason
end

local function handleAdjust(actor, descriptor)
  local target = resolveTarget(descriptor.target)
  if not target then
    sendMessage(actor, "GRPS: target not found.")
    return
  end

  local original = descriptor.amount or 0
  local amount = Bridge.clampAdjustment(original)
  if amount ~= original then
    sendMessage(actor, "GRPS: amount adjusted to " .. tostring(amount) .. ".")
  end
  if amount == 0 then
    sendMessage(actor, "GRPS: specify a non-zero amount.")
    return
  end

  local reason = sanitizeReason(descriptor.reason)

  local ok, response = Bridge.adjustPoints({
    actor = actor,
    target = target,
    amount = amount,
    reason = reason,
  })

  if ok then
    sendMessage(actor, "GRPS: adjustment submitted (" .. tostring(amount) .. ").")
    queueSync(actor)
    if typeof(target) == "Instance" then
      queueSync(target)
    end
  else
    sendMessage(actor, "GRPS: adjustment failed (" .. tostring(response) .. ").")
  end
end

local function handleWarn(actor, descriptor)
  local target = resolveTarget(descriptor.target)
  if not target then
    sendMessage(actor, "GRPS: target not found.")
    return
  end

  local reason = sanitizeReason(descriptor.reason)

  local ok, response = Bridge.warn({
    actor = actor,
    target = target,
    reason = reason,
  })

  if ok then
    sendMessage(actor, "GRPS: warning submitted.")
    if typeof(target) == "Instance" then
      queueSync(target)
    end
  else
    sendMessage(actor, "GRPS: warning failed (" .. tostring(response) .. ").")
  end
end

local function processCommand(player, message)
  local descriptor, err = parseCommand(message)
  if not descriptor then
    if err == "USAGE" then
      sendMessage(player, "GRPS usage: !grps add|sub <user> <amount> <reason> | !grps warn <user> <reason>")
    elseif err == "REASON_REQUIRED" then
      sendMessage(player, "GRPS: a reason is required.")
    elseif err == "UNKNOWN_ACTION" then
      sendMessage(player, "GRPS: unknown action.")
    end
    return
  end

  if not Bridge.isAuthorised(player) then
    sendMessage(player, "GRPS: insufficient permissions.")
    return
  end

  if descriptor.type == "adjust" then
    handleAdjust(player, descriptor)
  elseif descriptor.type == "warn" then
    handleWarn(player, descriptor)
  end
end

local function onPlayerAdded(player)
  local stats, koValue, woValue = ensureLeaderstats(player)
  attachListeners(player, stats, koValue, woValue)
  queueSync(player)

  connections[player.UserId] = connections[player.UserId] or {}
  table.insert(connections[player.UserId], player.Chatted:Connect(function(message)
    processCommand(player, message)
  end))
end

local function onPlayerRemoving(player)
  disconnectPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
  onPlayerAdded(player)
end
