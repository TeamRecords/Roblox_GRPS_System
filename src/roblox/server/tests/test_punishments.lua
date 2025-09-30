local Punishments = require(script.Parent.Parent.punishments)
local Policy = require(script.Parent.Parent.Parent.shared.policy)

return function(t)
  local policy = Policy.load()
  local store = { data = {} }
  function store:get(key)
    return self.data[key]
  end
  function store:set(key, value)
    self.data[key] = value
  end

  local auditEvents = {}
  local pun = Punishments.new(policy, { store = store, clock = function() return 100 end, audit = function(evt) table.insert(auditEvents, evt) end })

  for _ = 1, 4 do
    pun:incrementWarn(123, 1, 'reason')
  end

  t:eq(pun:evaluate(123), 'TRIAL', 'trial threshold hit')
  local untilTimestamp = pun:applyTrialSuspension(123, 1, 4)
  t:eq(untilTimestamp, 100 + 14 * 86400, 'trial duration applied')

  pun:incrementWarn(123, 1, 'reason')
  t:eq(pun:evaluate(123), 'SEVERE', 'severe threshold hit')

  local state = pun:getState(123)
  t:eq(state.warn_count, 5, 'warn count persisted')
  t:eq(state.suspended, true, 'suspension stored')
  t:eq(state.banned or false, false, 'ban not yet applied')

  pun:applySevereBan(123, 1, state.warn_count)
  local afterBan = pun:getState(123)
  t:eq(afterBan.banned, true, 'ban stored')
  t:eq(#auditEvents > 0, true, 'audit events emitted')
end
