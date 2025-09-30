local P={}
local function levelOf(actor) return actor and actor:GetAttribute('RLE_LEVEL') or 'LR' end function P.canWarn(actor) local l=levelOf(actor) return (l=='MR'or l=='D&I'or l=='CMD'or l=='CCM'or l=='LDR') end function P.canBan(actor) local l=levelOf(actor) return (l=='CMD'or l=='CCM'or l=='LDR') end return P
