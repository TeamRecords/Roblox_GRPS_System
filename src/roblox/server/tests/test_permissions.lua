local Permissions = require(script.Parent.Parent.permissions)
local Policy = require(script.Parent.Parent.Parent.shared.policy)

return function(t)
  local policy = Policy.load()
  local perms = Permissions.new(policy)

  t:eq(perms:canWarn({ RLE_ROLE = 'Volt Specialist II' }), true, 'MR can warn')
  t:eq(perms:canWarn({ RLE_ROLE = 'Shock Trooper I' }), false, 'LR cannot warn')
  t:eq(perms:canBan({ RLE_ROLE = 'Electro Colonel' }), true, 'CMD can ban')
  t:eq(perms:canBan({ RLE_ROLE = 'Tempest Major' }), false, 'Tempest cannot ban')
  t:eq(perms:canEarn({ RLE_ROLE = 'Suspended' }), false, 'suspended cannot earn')
  t:eq(perms:isIgnored('Guest'), true, 'guest ignored')
  t:eq(perms:getAdjustLimit({ RLE_ROLE = 'Ambassador' }), 25, 'Ambassador adjustment limit')
  t:eq(perms:canAdjustPoints({ RLE_ROLE = 'Ambassador' }, 10), true, 'Ambassador can adjust 10')
  t:eq(perms:canAdjustPoints({ RLE_ROLE = 'Ambassador' }, 30), false, 'Ambassador cannot adjust 30')
  t:eq(perms:canAdjustPoints({ RLE_ROLE = 'Shock Trooper I' }, 1), false, 'LR cannot adjust')

  local custom = Permissions.new(policy, { defaultRole = 'Guest', resolveRole = function() return 'Captain II' end })
  t:eq(custom:canWarn({}), true, 'custom resolver respected')
end
