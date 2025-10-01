local DataStore = require(script.Parent.Parent.datastore)

return function(t)
  local now = 0
  local store = DataStore.new({
    clock = function()
      return now
    end,
    historyLimit = 2,
  })

  store:updatePlayer(1, function(record)
    record.username = "Alpha"
    record.points = 10
    record.totals.daily = 10
    record.totals.weekly = 10
    record.history = {}
    return record
  end, { now = now })

  now = 172800 -- two days later
  store:updatePlayer(1, function(record)
    t:eq(record.totals.daily, 0, "daily reset after new day")
    t:eq(record.totals.weekly, 10, "weekly persists within same week")
    record.points = (record.points or 0) + 5
    record.totals.daily = (record.totals.daily or 0) + 5
    record.totals.weekly = (record.totals.weekly or 0) + 5
    record.history = record.history or {}
    table.insert(record.history, { id = 1 })
    table.insert(record.history, { id = 2 })
    table.insert(record.history, { id = 3 })
    return record
  end, { now = now })

  local player = store:getPlayer(1)
  t:eq(#player.history, 2, "history trimmed to limit")
  t:eq(player.history[1].id, 2, "oldest entries dropped")

  store:updatePlayer(2, function(record)
    record.username = "Bravo"
    record.points = 40
    record.kos = 5
    record.wos = 2
    return record
  end)

  store:updatePlayer(1, function(record)
    record.kos = 3
    record.wos = 4
    return record
  end)

  local top = store:leaderboardTop(2)
  t:eq(top[1].userId, 2, "leaderboard sorted by points")
  t:eq(top[2].userId, 1, "second entry retained")

  local records = store:records(5)
  t:eq(records.kos[1].userId, 2, "kos record is bravo")
  t:eq(records.wos[1].userId, 1, "wos record is alpha")
end
