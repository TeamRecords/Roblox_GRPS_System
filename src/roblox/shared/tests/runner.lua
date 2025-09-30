-- src/roblox/shared/tests/runner.lua
-- Minimal test runner (text output only)
local function eq(a,b,msg)
	if a ~= b then
		error("ASSERT FAIL: "..(msg or "").." expected "..tostring(b).." got "..tostring(a))
	end
end

local tests = {}

function tests.run()
	print("[TEST] running...")
	for name, fn in pairs(tests) do
		if type(fn) == "function" then
			fn({ eq = eq })
			print("[PASS] "..name)
		end
	end
end

return tests
