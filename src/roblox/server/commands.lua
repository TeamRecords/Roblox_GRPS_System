local C={}
local Perm=require(script.Parent.permissions)
local Pun=require(script.Parent.punishments)
local Policy=require(script.Parent.Parent.shared.policy)
local policy
function C.init() policy=Policy.load() Pun.init(policy) end local function say(p,msg) print('[CMD]', p and p.Name or 'server', msg) end function C.warn(actor,targetUserId,reason) if not Perm.canWarn(actor) then return say(actor,'No permission') end local count=Pun.incrementWarn(targetUserId,actor and actor.UserId or 0,reason or 'unspecified') local s=Pun.evaluate(targetUserId,actor and actor.UserId or 0) if s=='TRIAL' then Pun.applyTrialSuspension(targetUserId,actor and actor.UserId or 0,count) say(actor,('User %d Suspended (Trial). Count=%d'):format(targetUserId,count)) elseif s=='SEVERE' then Pun.applySevereBan(targetUserId,actor and actor.UserId or 0,count) say(actor,('User %d Banned (Severe). Count=%d'):format(targetUserId,count)) else say(actor,('Warn added. Count=%d'):format(count)) end end return C
