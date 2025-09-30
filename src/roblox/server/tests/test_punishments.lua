local P=require(script.Parent.Parent.punishments)
local Policy=require(script.Parent.Parent.Parent.shared.policy)
return function(t) local pol=Policy.load(); P.init(pol); local uid=123; for i=1,4 do P.incrementWarn(uid,0,'x') end t:eq(P.evaluate(uid,0),'TRIAL','trial') end
