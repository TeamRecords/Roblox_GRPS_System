local function eq(actual, expected, message)
  if actual ~= expected then
    error(('ASSERT %s expected %s got %s'):format(message or '', tostring(expected), tostring(actual)))
  end
end

local function truthy(value, message)
  if not value then
    error(('ASSERT %s expected truthy value'):format(message or ''))
  end
end

local registry = {}

local function register(name, factory)
  registry[name] = factory
end

register('permissions', require(script.Parent.test_permissions))
register('punishments', require(script.Parent.test_punishments))

local Runner = {}

function Runner.run()
  print('[TEST] start server suite')
  for name, factory in pairs(registry) do
    if type(factory) == 'function' then
      factory({ eq = eq, truthy = truthy })
      print('[PASS]', name)
    end
  end
  print('[TEST] end server suite')
end

return Runner
