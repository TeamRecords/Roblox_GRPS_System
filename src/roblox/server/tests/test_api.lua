local Api = require(script.Parent.Parent.api)

local FakeHttp = {}
FakeHttp.__index = FakeHttp

function FakeHttp.new(response)
  local self = setmetatable({
    responses = response and { response } or {},
    requests = {},
  }, FakeHttp)
  return self
end

function FakeHttp:pushResponse(response)
  table.insert(self.responses, response)
end

function FakeHttp:RequestAsync(options)
  table.insert(self.requests, options)
  local response = table.remove(self.responses, 1)
  if not response then
    response = {
      Success = true,
      StatusCode = 200,
      StatusMessage = "OK",
      Body = { ok = true },
    }
  end
  return response
end

function FakeHttp:JSONEncode(value)
  return value
end

function FakeHttp:JSONDecode(value)
  return value
end

return function(t)
  local http = FakeHttp.new()
  local api = Api.new({
    baseUrl = "https://backend.example.com",
    http = http,
    jsonEncode = function(payload)
      http.lastEncoded = payload
      return payload
    end,
    jsonDecode = function(value)
      return value
    end,
    apiKey = "secret",
  })

  http:pushResponse({
    Success = true,
    StatusCode = 200,
    StatusMessage = "OK",
    Body = { player = { userId = 1 }, decision = nil },
  })

  local snapshot = {
    userId = 1,
    username = "Alpha",
    rankPoints = 150,
    kos = 10,
    wos = 5,
  }

  local response, err = api:publishSnapshot(snapshot, {
    evaluate = true,
    apply = false,
    experienceKey = "nexus",
    actorUserId = 42,
  })

  t:eq(err, nil, "snapshot publish succeeded")
  t:eq(response.player.userId, 1, "response parsed")

  local request = http.requests[#http.requests]
  t:eq(request.Method, "POST", "uses POST")
  t:eq(string.find(request.Url, "/roblox/events/player-activity", 1, true) ~= nil, true, "correct path")
  t:eq(request.Headers["x-grps-api-key"], "secret", "api key header set")
  t:eq(request.Headers["x-grps-evaluate"], "true", "evaluate header set")
  t:eq(request.Headers["x-roblox-experience"], "nexus", "experience header set")
  t:eq(request.Headers["x-grps-actor"], "42", "actor header set")
  t:eq(http.lastEncoded, snapshot, "payload encoded")

  http:pushResponse({
    Success = true,
    StatusCode = 200,
    StatusMessage = "OK",
    Body = { userId = 99 },
  })
  local player = api:getPlayer(99)
  t:eq(player.userId, 99, "player request decoded")
  local getRequest = http.requests[#http.requests]
  t:eq(getRequest.Method, "GET", "player uses GET")
  t:eq(string.find(getRequest.Url, "/players/99") ~= nil, true, "player url correct")

  http:pushResponse({
    Success = false,
    StatusCode = 500,
    StatusMessage = "Error",
    Body = { message = "boom" },
  })
  local result, errorPayload = api:requestDecision({ userId = 5 })
  t:eq(result, nil, "decision fails on error")
  t:eq(errorPayload.statusCode, 500, "error propagated")
end
