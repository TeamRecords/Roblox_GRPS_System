local Ranks = require(script.Parent.Parent.ranks)

return function(t)
  local ranks = {
    { name = 'A', minPoints = 0, minTimeDays = 0, level = 'LR' },
    { name = 'B', minPoints = 10, minTimeDays = 1, level = 'LR', requiredRecs = 1 },
    { name = 'C', minPoints = 20, minTimeDays = 2, level = 'MR', minConduct = 3 },
  }

  t:eq(Ranks.find(ranks, 'B').level, 'LR', 'find rank')
  t:eq(Ranks.next(ranks, 'A').name, 'B', 'next rank')
  t:eq(Ranks.previous(ranks, 'C').name, 'B', 'previous rank')

  local ok, reason = Ranks.meetsThresholds({ points = 5, timeInRankDays = 0 }, ranks[2])
  t:eq(ok, false, 'fails points')
  t:eq(reason, 'points', 'points reason')

  local user = { points = 25, timeInRankDays = 3, recs = 1, conductScore = 4 }
  local passes, failReason = Ranks.meetsThresholds(user, ranks[3])
  t:eq(passes, true, 'passes thresholds')
  t:eq(failReason, nil, 'no failure reason')

  local permitted, permReason = Ranks.isPromotionPermitted({ suspended_until = os.time() + 100 }, { punishments = { trial_lock_promotion = true } })
  t:eq(permitted, false, 'promotion blocked while suspended')
  t:eq(permReason, 'permitted', 'promotion reason')
end
