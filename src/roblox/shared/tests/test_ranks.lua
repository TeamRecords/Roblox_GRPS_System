local R=require(script.Parent.Parent.ranks)
return function(t) local rs={{name='A',minPoints=0,minTimeDays=0,level='LR'},{name='B',minPoints=10,minTimeDays=1,level='LR'}} t:eq(R.next(rs,'A'),'B','next'); local ok=R.meetsThresholds({points=20,timeInRankDays=2},rs[2]); t:eq(ok,true,'thresholds') end
