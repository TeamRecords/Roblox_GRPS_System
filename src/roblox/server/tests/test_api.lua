local Api = require(script.Parent.Parent.api)
local Policy = require(script.Parent.Parent.Parent.shared.policy)
local Audit = require(script.Parent.Parent.audit)
local DataStore = require(script.Parent.Parent.datastore)

return function(t)
  local clockValue = 1000
  local function clock()
    return clockValue
  end

  local auditLines = {}
  local audit = Audit.new({
    clock = clock,
    source = "test",
    static = { suite = "api" },
    writer = function(line)
      table.insert(auditLines, line)
    end,
  })

  local store = DataStore.new({ clock = clock, historyLimit = 5 })
  local policy = Policy.load()

  local api = Api.new({
    policy = policy,
    audit = audit,
    dataStore = store,
    clock = clock,
  })

  local ok, result = api:recordEvent({ UserId = 9001 }, {
    userId = 101,
    username = "Alpha",
    rank = "Volt Specialist II",
    event = { type = "activity_tick_5min" },
    experience = { key = "nexus", universeId = 12345 },
  })

  t:eq(ok, true, "event accepted")
  t:eq(result.delta, 1, "activity weight applied")

  clockValue = clockValue + 10
  ok, result = api:recordEvent({ UserId = 9001 }, {
    userId = 101,
    rank = "Volt Specialist II",
    event = { type = "ko" },
  })
  t:eq(ok, true, "ko recorded")
  t:eq(result.delta > 0, true, "ko yields points")

  local denied, reason = api:recordEvent({ UserId = 9001 }, {
    userId = 101,
    rank = "Volt Specialist II",
    event = { type = "ko" },
  })
  t:eq(denied, false, "cooldown enforced")
  t:eq(reason, "KO_COOLDOWN", "cooldown reason returned")

  local blocked, blockedReason = api:recordEvent(nil, {
    userId = 202,
    username = "Suspended", -- Suspended role cannot earn
    rank = "Suspended",
    event = { type = "activity_tick_5min" },
  })
  t:eq(blocked, false, "suspended denied")
  t:eq(blockedReason, "NOT_PERMITTED", "permission reason returned")

  local adjustActor = { RLE_ROLE = "Ambassador", UserId = 600 }
  local adjustOk, adjustResult = api:adjustPoints(adjustActor, {
    userId = 101,
    amount = 5,
    reason = "Command bonus",
    experience = { key = "training_site", universeId = 54321 },
  })
  t:eq(adjustOk, true, "adjustment succeeds")
  t:eq(adjustResult.delta, 5, "adjustment delta returned")

  local adjustDenied, adjustReason = api:adjustPoints(adjustActor, {
    userId = 101,
    amount = 30,
    reason = "Too generous",
  })
  t:eq(adjustDenied, false, "adjustment limit enforced")
  t:eq(adjustReason, "LIMIT_EXCEEDED", "limit reason returned")

  local warnActor = { RLE_ROLE = "Volt Specialist II", UserId = 500 }
  local warnOk, warnPayload = api:warn(warnActor, 101, "Misconduct", {
    experience = { key = "training_site" },
  })
  t:eq(warnOk, true, "warn succeeded")
  t:eq(type(warnPayload.count), "number", "warn count tracked")

  local playerSummary = api:getPlayer(101)
  t:eq(playerSummary.player.userId, 101, "player summary returned")
  t:eq(playerSummary.player.kos >= 1, true, "kos tracked")
  t:eq(playerSummary.player.warns, warnPayload.count, "warns persisted")
  local manualEntry
  local warnEntry
  for _, entry in ipairs(playerSummary.history) do
    if entry.type == "manual_award" then
      manualEntry = entry
    elseif entry.type == "warn" then
      warnEntry = entry
    end
  end
  t:neq(manualEntry, nil, "manual adjustment recorded")
  t:eq(manualEntry.experience.key, "training_site", "adjustment experience captured")
  t:neq(warnEntry, nil, "warn history appended")
  t:eq(warnEntry.experience.key, "training_site", "warn experience captured")

  clockValue = clockValue + 60
  api:recordEvent({ UserId = 42 }, {
    userId = 303,
    username = "Bravo",
    rank = "Captain I",
    event = { type = "operation_complete" },
  })

  local top = api:getLeaderboardTop(5)
  t:eq(#top.players >= 2, true, "multiple players on leaderboard")
  t:eq(top.players[1].points >= top.players[2].points, true, "leaderboard sorted descending")

  local records = api:getLeaderboardRecords(5)
  t:eq(type(records.kos), "table", "records returned")
  t:eq(type(records.wos), "table", "wo records returned")

  t:eq(#auditLines > 0, true, "audit lines emitted")

  local snapshot = api:getPolicy()
  snapshot.points.weights.activity_tick_5min = 999
  local nextSnapshot = api:getPolicy()
  t:eq(nextSnapshot.points.weights.activity_tick_5min, policy.points.weights.activity_tick_5min, "policy deep copied")
end
