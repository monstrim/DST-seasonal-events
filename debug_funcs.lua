GLOBAL.CHEATS_ENABLED = true

--Debugging global functions

-- Day
GLOBAL.NextDay = function() GLOBAL.TheWorld:PushEvent('ms_nextcycle') end

-- Season
GLOBAL.NextWinter = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.season == 'winter' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setseason', 'summer') end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setseason', 'winter') end)
end
GLOBAL.NextSummer = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.season == 'summer' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setseason', 'winter') end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setseason', 'summer') end)
end
GLOBAL.NextAutumn = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.season == 'autumn' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setseason', 'spring') end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setseason', 'autumn') end)
end
GLOBAL.NextSpring = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.season == 'spring' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setseason', 'autumn') end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setseason', 'spring') end)
end

-- Moon
GLOBAL.NextNew = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.moonphase == 'new' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='full', iswaxing=false}) end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='new', iswaxing=true}) end)
end
GLOBAL.NextFull = function()     
    local TheWorld = GLOBAL.TheWorld
    if TheWorld.state.moonphase == 'full' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='new', iswaxing=false}) end)
    end 
    TheWorld:DoTaskInTime(0.5, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='full', iswaxing=true}) end)
end
GLOBAL.NextMoon = GLOBAL.NextNew

-- Year
GLOBAL.NextYear = function()
    local TheWorld = GLOBAL.TheWorld
    TheWorld:DoTaskInTime(0, function(inst) GLOBAL.NextWinter() end)
    TheWorld:DoTaskInTime(1, function(inst) GLOBAL.NextMoon() end)
    TheWorld:DoTaskInTime(2, function(inst) GLOBAL.NextMoon() end)
end

-- F10 for next day
AddGamePostInit(function()
    GLOBAL.TheInput:AddKeyHandler(function (key, down)
        if down then
            if key == GLOBAL.KEY_F10 then
                GLOBAL.NextDay()
            elseif key == GLOBAL.KEY_F11 then
                GLOBAL.NextYear()
            end
        end
    end)
end)
