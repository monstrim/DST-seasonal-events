assert = GLOBAL.assert
require = GLOBAL.require
----------------------------------------------------

local year_of_list = {}
local current_year_of
local seasonal_events = {}
local season

local TheWorld

local WORLD_EXTRA_EVENTS = GLOBAL.WORLD_EXTRA_EVENTS
local SPECIAL_EVENTS = GLOBAL.SPECIAL_EVENTS
local IsSpecialEventActive = GLOBAL.IsSpecialEventActive

----------------------------------------------------

local function _announce(template, event)
    local prettyname = event:gsub("_", " "):gsub("^%l", string.upper)
    --ThePlayer.components.talker:Say(string.format(template, prettyname), true)
    for i,v in ipairs(GLOBAL.AllPlayers) do v.components.talker:Say(string.format(template, prettyname)) end
end

local function _playSound(sound, name, volume)
    for i,v in ipairs(GLOBAL.AllPlayers) do v.SoundEmitter:PlaySound(sound, name, volume) end
end

----------------------------------------------------
-- Aux functions to start and stop special events while the game is running. Spawning of hidden kittens 
-- and halloween trinkets (and presumbly some future new YOTx setups) is already handled by single game 
-- function, but the carnival host is only spawned on the carnival's post init
----------------------------------------------------

local function _startCrow()
    TheWorld.components.carnivalevent:OnPostInit()
    local crow = GLOBAL.c_find("carnival_host")
    crow.sg:GoToState("glide")
end


local function _stopCrow()
    local crow = GLOBAL.c_find("carnival_host")
    crow.sg:GoToState("flyaway")
    crow:DoTaskInTime(3, crow.Remove)
end

----------------------------------------------------

function StartEvent (event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE or IsSpecialEventActive(event) then 
        return
    end
    
    -- game code to set WORLD_EXTRA_EVENTS and TECH
    -- usually only run on startup
    GLOBAL.ApplyExtraEvent(event)
    
    -- startup event mid-game
    if event == SPECIAL_EVENTS.CARNIVAL then
        _startCrow()
    elseif TheWorld.components.specialeventsetup ~= nil then
        TheWorld.components.specialeventsetup:SetupNewSpecialEvent(event)
    else
        print('TheWorld.components.specialeventsetup not found')
    end
    
end

----------------------------------------------------

function StopEvent (event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE or not IsSpecialEventActive(event) then 
        return
    end
    
    -- game has no code to STOP an event, so we replicate ApplyExtraEvent's logic plus a check 
    -- so we don't disable tech on a current WORLD_SPECIAL_EVENT
    WORLD_EXTRA_EVENTS[event] = nil
    print("Removing extra World Event: " .. tostring(event))

    if IsSpecialEventActive(event) then 
        --active as WORLD_SPECIAL_EVENT
        return
    end
    
    -- set tech to LOST
    for k, v in pairs(SPECIAL_EVENTS) do
        if v == event and v ~= SPECIAL_EVENTS.NONE then
            local tech = GLOBAL.TECH[k]
            if tech ~= nil then
                tech.SCIENCE = 10
            end
        end
    end
    
    -- cleanup event
    if event == SPECIAL_EVENTS.CARNIVAL then
        _stopCrow()
    elseif TheWorld.components.specialeventsetup ~= nil then
        TheWorld.components.specialeventsetup:ShutdownPrevSpecialEvent(event)
    else
        print('TheWorld.components.specialeventsetup not found')
    end
    
end

GLOBAL.StartEvent = StartEvent
GLOBAL.StopEvent = StopEvent

GLOBAL.NextDay = function() TheWorld:PushEvent('ms_nextcycle') end

GLOBAL.NextWinter = function()     
    if TheWorld.state.season == 'winter' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setseason', 'summer') end)
    end 
    TheWorld:DoTaskInTime(1, function() TheWorld:PushEvent('ms_setseason', 'winter') end)
end

GLOBAL.NextNew = function()     
    if TheWorld.state.moonphase == 'new' then 
        TheWorld:DoTaskInTime(0, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='full', iswaxing=false}) end)
    end 
    TheWorld:DoTaskInTime(1, function() TheWorld:PushEvent('ms_setmoonphase', {moonphase='new', iswaxing=true}) end)
end

----------------------------------------------------
--Seasonal event start sounds

local function _winterfeastjingle()
    local bell = 'dontstarve/creatures/together/deer/bell'
    local chain = 'dontstarve/creatures/together/deer/chain'
    
    TheWorld:DoTaskInTime(0.0, function() _playSound(bell, nil, 0.4) end)
    TheWorld:DoTaskInTime(0.4, function() _playSound(bell, nil, 0.4) end)
    TheWorld:DoTaskInTime(0.8, function() _playSound(bell, nil, 0.8) end)
    
    TheWorld:DoTaskInTime(1.6, function() _playSound(bell, nil, 0.5) end)
    TheWorld:DoTaskInTime(2.0, function() _playSound(bell, nil, 0.5) end)
    TheWorld:DoTaskInTime(2.4, function() _playSound(bell, nil, 1.0) end)
end
GLOBAL.jingle = _winterfeastjingle


local function _hallowednightstorm()
    TheWorld:DoTaskInTime(1, function() GLOBAL.SpawnPrefab('thunder_close') end)
    TheWorld:DoTaskInTime(2, function() GLOBAL.SpawnPrefab('thunder_far') end)
    TheWorld:DoTaskInTime(3, function() GLOBAL.SpawnPrefab('thunder_close') end)
    TheWorld:DoTaskInTime(5, function() GLOBAL.SpawnPrefab('thunder_far') end)
    TheWorld:DoTaskInTime(8, function() GLOBAL.SpawnPrefab('thunder_close') end)
    TheWorld:DoTaskInTime(13, function() GLOBAL.SpawnPrefab('thunder_far') end)
end

GLOBAL.storm = _hallowednightstorm




----------------------------------------------------
-- Main mod code
----------------------------------------------------

local function _seasonInit (world)
    
    local function early (season_length) return math.ceil(season_length/4) end
    local function mid (season_length) return math.ceil(season_length/2) end
    local function late (season_length) return math.ceil(season_length*3/4) end
    
    local spring = world.state.autumnlength
    local summer = world.state.winterlength
    local autumn = world.state.springlength
    local winter = world.state.summerlength
    season = world.state.season
    
    seasonal_events = {
        
        HALLOWED_NIGHTS = {
            season = "autumn", 
            start = mid(autumn), 
            stop = late(autumn),
            sound_fn = _hallowednightstorm
        },
        
        WINTERS_FEAST = {
            season = "winter", 
            start = early(winter), 
            stop = mid(winter), 
            sound_fn = _winterfeastjingle
        },
        
        CARNIVAL = {
            season = "summer", 
            start = early(summer), 
            stop = late(summer)
        }
    }
end


local function _newYearInit (world)
    for k,v in pairs(SPECIAL_EVENTS) do
        if GLOBAL.IS_YEAR_OF_THE_SPECIAL_EVENTS[v] then
            table.insert(year_of_list, v)
        end
    end
    
    current_year_of = year_of_list[world.state.current_year_num]
    StartEvent(current_year_of)
end


local function _checkSeasonalEvents(world)
    local currentday = world.state.elapseddaysinseason + 1
    
    for k, v in pairs(seasonal_events) do
        event = SPECIAL_EVENTS[k]
        
        if season == v.season and currentday >= v.start and currentday <= v.stop then
            if not IsSpecialEventActive(event) then
                StartEvent(event)
                _announce('%s has begun!', event)
                if v.sound then
                    --TODO: test difference between TheWorld and ThePlayer in multiplayer
                    --is this an all client mod?
                    _playSound(v.sound)
                elseif v.sound_fn then
                    v.sound_fn()
                end
            end
        else
            if IsSpecialEventActive(event) then
                StopEvent(event)
                _announce('%s is over.', event)
            end
        end
    end

end

----------------------------------------------------

local function OnCyclesChange(world)
    _checkSeasonalEvents(world)
end


local function OnMoonChange(world)
    if world.state.moonphase == 'new' then
        world.state.current_new_moon = world.state.current_new_moon + 1
        
        if world.state.current_new_moon == 2 then
            --world:StopWatchingWorldState('moonphase', OnMoonChange)
            StopEvent(current_year_of)
            
            if world.state.current_year_num == #year_of_list then
                world.state.current_year_num = 1
            else
                world.state.current_year_num = world.state.current_year_num + 1
            end
            
            current_year_of = year_of_list[world.state.current_year_num]
            StartEvent(current_year_of)
            
            _announce('Happy new %s!', current_year_of)
            for i, v in ipairs(GLOBAL.AllPlayers) do v:PushEvent("startflareoverlay",{r=1,g=0.6,b=0.6}) end
            _playSound("wickerbottom_rework/megaflare/explode", nil, 1)
        end
    end 
end


local function OnSeasonChange(world) 
    season = world.state.season
    
    -- for extremely short seasons, you may get two winters before two new moons, so check for that too
    -- TODO: check wether winter is an available season, oherwise push forward
    ---- (check at startup and save as variable)
    if season == 'winter' and world.state.current_new_moon >= 2 then
        world.state.current_new_moon = 0
    end
end

----------------------------------------------------

local function _stateInit (worldstate)
    worldstate.data.current_year_num = 1
    worldstate.data.current_new_moon = 2
end


local function _worldInit (world)
    assert(world == GLOBAL.TheWorld, '[teste] invalid world')
    
    TheWorld = GLOBAL.TheWorld
    --ThePlayer = GLOBAL.ThePlayer
    
    _seasonInit(world)
    _newYearInit(world)
    _checkSeasonalEvents(world)

    world:WatchWorldState("cycles", OnCyclesChange)
    world:WatchWorldState("season", OnSeasonChange)
    world:WatchWorldState('moonphase', OnMoonChange)
    world:WatchWorldState("springlength", _seasonInit)
    world:WatchWorldState("summerlength", _seasonInit)
    world:WatchWorldState("autumnlength", _seasonInit)
    world:WatchWorldState("winterlength", _seasonInit)
end


AddComponentPostInit ('worldstate', _stateInit)
AddPrefabPostInit ('world', function (inst) inst:DoTaskInTime(1, _worldInit) end)