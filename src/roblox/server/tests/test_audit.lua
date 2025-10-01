local Audit = require(script.Parent.Parent.audit)

return function(t)
  local lines = {}
  local audit = Audit.new({
    clock = function()
      return 123
    end,
    source = "test",
    static = { system = "unit" },
    writer = function(line)
      table.insert(lines, line)
    end,
  })

  local output = audit:log({ action = "PING", payload = { ok = true } })
  t:eq(#lines, 1, "writer invoked")
  t:eq(lines[1], output, "log returns emitted line")
  t:eq(output, '{"action":"PING","at":123,"payload":{"ok":true},"source":"test","system":"unit"}', "json encoded")

  local encoded = Audit.encode({ level = "info", code = 42 })
  t:eq(encoded, '{"code":42,"level":"info"}', "encode helper")
end
