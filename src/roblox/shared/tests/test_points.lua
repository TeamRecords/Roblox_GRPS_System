local Points = require(script.Parent.Parent.points)

return function(t)
  local weights = {
    activity_tick_5min = 1,
    training_complete = 15,
    operation_complete = 25,
    ko = 0.25,
    wo = -0.1,
  }

  t:eq(Points.calculateDelta({ type = 'training' }, weights), 15, 'training weight')
  t:eq(Points.calculateDelta({ type = 'ko', magnitude = 4 }, weights), 1, 'scaled ko')

  local delta = Points.applyCaps(490, 2400, 20, { daily = 500, weekly = 2500 })
  t:eq(delta, 10, 'daily cap clamps delta')

  local ok, reason = Points.enforceAntiAbuse({ type = 'activity', duration = 120 }, { now = 10 }, { activity_min_seconds = 300 })
  t:eq(ok, false, 'activity too short')
  t:eq(reason, 'ACTIVITY_TOO_SHORT', 'activity reason')

  local resolved, antiReason = Points.resolve(
    { type = 'ko' },
    { daily = 0, weekly = 0 },
    { weights = weights, anti_abuse = { ko_cooldown_seconds = 60 } },
    { now = 100, lastKoAt = 50 }
  )
  t:eq(resolved, 0, 'cooldown blocks points')
  t:eq(antiReason, 'KO_COOLDOWN', 'cooldown reason')

  local awarded = Points.resolve(
    { type = 'operation_complete' },
    { daily = 100, weekly = 200 },
    { weights = weights, caps = { daily = 500, weekly = 2500 } },
    {}
  )
  t:eq(awarded, 25, 'operation delta')
end
