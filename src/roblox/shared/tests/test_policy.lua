local Policy = require(script.Parent.Parent.policy)

return function(t)
  local policy = Policy.load()
  local rank = Policy.getRank(policy, 'Shock Trooper II')
  t:eq(rank.level, 'LR', 'rank lookup')
  t:eq(Policy.getNextRank(policy, 'Shock Trooper II').name, 'Volt Specialist I', 'next rank lookup')

  local overrides = Policy.load({ overrides = { punishments = { trial_threshold = 3 } } })
  t:eq(overrides.punishments.trial_threshold, 3, 'override applied')

  local descriptor = Policy.getPermissionDescriptor(policy, 'Tempest Major')
  t:eq(descriptor.canWarn, true, 'permission lookup')
end
