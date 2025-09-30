-- loads policy (stub—swap for JSON ingest)
local P={}
function P.load() return {punishments={trial_threshold=4,severe_threshold=7,trial_days=14,trial_lock_promotion=true}} end
return P
