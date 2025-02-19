--Debugging global functions

GLOBAL.NextDay = function() GLOBAL.TheWorld:PushEvent('ms_nextcycle') end

GLOBAL.NextWinter = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.season == 'winter' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setseason', 'summer') end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setseason', 'winter') end)
end

GLOBAL.NextNew = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.moonphase == 'new' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='full', iswaxing=false}) end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='new', iswaxing=true}) end)
end
