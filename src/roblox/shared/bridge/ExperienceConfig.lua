--[[
Configuration template for connecting an auxiliary experience to the GRPS.

Duplicate this ModuleScript into the target experience (for example inside
`ServerScriptService/GRPSBridge/ExperienceConfig`) and adjust the values to
match the deployment. The automation backend expects all requests to include
an `experienceKey` so it can route updates to the correct datastore.
--]]

return {
  -- Unique identifier for the experience. Use snake_case names so they can
  -- be embedded into URLs without encoding issues.
  experienceKey = "training_facility",

  -- Optional override if the automation API uses a different universe ID
  -- than `game.GameId`. Leave nil to automatically send the current universe.
  universeId = nil,

  -- Base URL for the automation API that fronts the GRPS backend.
  automationBaseUrl = "https://automation.example.com",

  -- Endpoint templates. The `{experienceKey}` token is replaced automatically.
  endpoints = {
    sync = "/integrations/experiences/{experienceKey}/leaderstats",
    adjust = "/integrations/experiences/{experienceKey}/adjust",
    warn = "/integrations/experiences/{experienceKey}/warn",
  },

  -- API key + header used for authentication. Replace the placeholder value
  -- and header name to match the deployed edge worker.
  apiKeyHeader = "x-grps-bridge-key",
  apiKey = "replace-me",

  -- Maximum manual adjustment (positive or negative) allowed from this
  -- experience. The GRPS backend enforces the same limit, so this acts as
  -- an early guard for command staff.
  maxAdjustment = 25,

  -- Synchronisation cadence in seconds. Each player that records activity,
  -- KO, or WO changes is batched into the next scheduled sync tick.
  syncIntervalSeconds = 30,

  -- Roblox group information used to authorise command and central command
  -- members. Supply the `groupId` and rank numbers that map to the Command
  -- and Central Command tiers.
  groupId = 0000000,
  commandRanks = { 200, 205, 210 },
  centralCommandRanks = { 220, 225, 230 },

  -- Optional fallback when group ranks are unavailable. When provided, the
  -- bridge checks these role names against `Player:GetAttribute("RLE_ROLE")`
  -- or `Player:GetAttribute("RLE_RANK")`.
  allowedRoles = {
    "Ambassador",
    "Envoy",
    "Tempest Major",
    "Electro Colonel",
    "Brigadier General",
    "Stormmarshal",
    "Imperator",
  },
  roleAttribute = "RLE_ROLE",
}
