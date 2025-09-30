local M=require(script.Parent.Parent.points)
return function(t) local w={activity_tick_5min=1,training_complete=15,operation_complete=25,ko=0.25,wo=-0.1}
t:eq(M.calculateDelta({type='training'},nil,w),15,'training'); local a=M.applyCaps(9,9,5,{daily=10,weekly=100}); t:eq(a,1,'cap') end
