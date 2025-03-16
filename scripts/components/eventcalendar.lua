--------------------------------------------------------------------------
--[[ EventCalendar class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

require "utils/ui_utils"
require "utils/event_utils"
-- require "event_utils" -- event setup/cleanup, crow, ?fanfarres?

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local year_of_list = {
    SPECIAL_EVENTS.YOTG, -- gobbler
    SPECIAL_EVENTS.YOTV, -- varg
    SPECIAL_EVENTS.YOTP, -- pig
    SPECIAL_EVENTS.YOTC, -- carrat
    SPECIAL_EVENTS.YOTB, -- beefalo
    SPECIAL_EVENTS.YOT_CATCOON, -- catcoon
    SPECIAL_EVENTS.YOTR, -- bunnyman
    SPECIAL_EVENTS.YOTD, -- dragonfly
    SPECIAL_EVENTS.YOTS, -- snake
}
local year_of_set = {}
for i,v in ipairs(year_of_list) do year_of_set[v] = true end

local seasonal_events = {
    autumn = {
        event = SPECIAL_EVENTS.HALLOWED_NIGHTS, 
        start = 'mid', 
        stop = 'late',
        fanfarre = _hallowednightstorm
    },
    
    winter = {
        event = SPECIAL_EVENTS.WINTERS_FEAST, 
        start = 'early', 
        stop = 'mid', 
        fanfarre = _winterfeastjingle
    },
    
    summer = {
        event = SPECIAL_EVENTS.CARNIVAL, 
        start = 'early', 
        stop = 'late',
        fanfarre = _carnivalconfetti
    }
}

local new_year_season = 'winter' -- TODO: change at init if winter disabled

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local current_year
local current_new_moon
local current_seasonal_event

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function StartEvent(event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE then
        print(string.format('[Yearly Seasonal Events] Event %s', event or 'nil'))
        return
    elseif IsSpecialEventActive(event) then 
        print(string.format('[Yearly Seasonal Events] Event %s already active', event))
        return
    end
    print(string.format('[Yearly Seasonal Events] Starting event %s', event))

    WORLD_EXTRA_EVENTS[event] = true

    -- startup event mid-game
    if event == SPECIAL_EVENTS.CARNIVAL then
        _startCarnival()
    elseif event == SPECIAL_EVENTS.WINTERS_FEAST then
        _startWintersFeast()
    elseif event == SPECIAL_EVENTS.YOTD then
        _startYOTD()
    end
    
    if TheWorld.components.specialeventsetup ~= nil then
        TheWorld.components.specialeventsetup:SetupNewSpecialEvent(event)
    else
        print('[Yearly Seasonal Events] TheWorld.components.specialeventsetup not found')
    end
end

local function StopEvent(event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE then
        print(string.format('[Yearly Seasonal Events] Event %s', event or 'nil'))
        return
    elseif not IsSpecialEventActive(event) then 
        print(string.format('[Yearly Seasonal Events] Event %s already inactive', event))
        return
    end
    print(string.format('[Yearly Seasonal Events] Stopping event %s', event))
    
    WORLD_EXTRA_EVENTS[event] = nil

    -- cleanup event
    if event == SPECIAL_EVENTS.CARNIVAL then
        _stopCarnival()
    elseif event == SPECIAL_EVENTS.WINTERS_FEAST then
        _stopWintersFeast()
    elseif event == SPECIAL_EVENTS.YOTD then
        _stopYOTD()
    end
    
    if TheWorld.components.specialeventsetup ~= nil then
        TheWorld.components.specialeventsetup:ShutdownPrevSpecialEvent(event)
    else
        print('[Yearly Seasonal Events] TheWorld.components.specialeventsetup not found')
    end
end

--------------------------------------------------------------------------

local function _worldEventsInit()
    -- Events launched after last update
    for v,_ in pairs(IS_YEAR_OF_THE_SPECIAL_EVENTS) do
        if not year_of_set[v] then
            print('[Yearly Seasonal Events] adding ' .. v)
            table.insert(year_of_list, v)
            year_of_set[v] = true
        end
    end

    -- If a Year Of is currently active, set it to current year, otherwise begin at the last
    if WORLD_SPECIAL_EVENT and IS_YEAR_OF_THE_SPECIAL_EVENTS[WORLD_SPECIAL_EVENT] then
        current_year = table.invert(year_of_list)[WORLD_SPECIAL_EVENT]
    else
        current_year = #year_of_list
    end
    WORLD_SPECIAL_EVENT = SPECIAL_EVENTS.NONE
    StartEvent(year_of_list[current_year])
end


local function _checkSeasonalEvents()
    local currentday = TheWorld.state.elapseddaysinseason + 1
    local event_data = seasonal_events[TheWorld.state.season]

    if event_data and (event_data.start_day < currentday) and (currentday <= event_data.stop_day) then
        if not IsSpecialEventActive(event_data.event) then
            StopEvent(current_seasonal_event)
            current_seasonal_event = event_data.event
            StartEvent(current_seasonal_event)
            if event_data.fanfarre then event_data.fanfarre() end
            _announce(current_seasonal_event)
        end
    else
        if current_seasonal_event then
            StopEvent(current_seasonal_event)
            current_seasonal_event = nil
        end
    end
    self:Sync()
end


local function _seasonInit ()
    --TODO: check if winter available
    new_year_season = 'winter' or 'TODO'
    
    local lengths = {
        spring = TheWorld.state.springlength,
        summer = TheWorld.state.summerlength,
        autumn = TheWorld.state.autumnlength,
        winter = TheWorld.state.winterlength,
    }
    local quarters = {
        early = function (season_length) return (season_length/4) end,
        mid = function (season_length) return (season_length/2) end,
        late = function (season_length) return (season_length*3/4) end,
    }
    for season, data in pairs(seasonal_events) do
        data.start_day = math.floor(quarters[data.start](lengths[season]))
        data.stop_day = math.ceil(quarters[data.stop](lengths[season]))

        -- fix for sad, sad rain on Winter's Feast
        if season == 'winter' and data.start_day < 2 then
            local offset = 2 - data.start_day
            data.start_day = 2
            data.stop_day = data.stop_day + offset
        end
    end
    _checkSeasonalEvents()
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:Sync()
    local replica = self.inst.replica.eventcalendar
    replica:SetYearEvent(year_of_list[current_year])
    replica:SetSeasonalEvent(current_seasonal_event)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnCyclesChange(inst)
    _checkSeasonalEvents()
end

local function OnMoonChange(inst)
    if TheWorld.state.moonphase == 'new' then
        current_new_moon = current_new_moon + 1
        
        if current_new_moon == 2 then
            StopEvent(year_of_list[current_year])
            current_year = (current_year == #year_of_list) and 1 or current_year + 1
            StartEvent(year_of_list[current_year])
            _fireworks()
            _announce(year_of_list[current_year])
            self:Sync()
        end
    end 
end

local function OnSeasonChange(inst)
    -- TODO: check wether winter is an available season, oherwise push forward
    ---- (check at startup and save as variable)
    if TheWorld.state.season == new_year_season and current_new_moon >= 2 then
        current_new_moon = 0
    end
end


--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

-- Initialize events and seasons
_worldEventsInit()
_seasonInit()
_checkSeasonalEvents()
current_new_moon = 2 --will zero on next winter

-- Listen for events
inst:WatchWorldState("cycles", OnCyclesChange)
inst:WatchWorldState("season", OnSeasonChange)
inst:WatchWorldState('moonphase', OnMoonChange)
inst:WatchWorldState("springlength", function(inst) _seasonInit() end)
inst:WatchWorldState("summerlength", function(inst) _seasonInit() end)
inst:WatchWorldState("autumnlength", function(inst) _seasonInit() end)
inst:WatchWorldState("winterlength", function(inst) _seasonInit() end)

-- Finally, sync
self:Sync()

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    data.current_year = current_year
    data.current_new_moon = current_new_moon
    return data
end

function self:OnLoad(data)
    -- _worldEventsInit()
    -- _seasonInit()
    -- _checkSeasonalEvents()

    if data ~= nil then
		if data.current_year ~= nil then
            if current_year and current_year ~= data.current_year then
                StopEvent(year_of_list[current_year])
            end
	        current_year = data.current_year
            StartEvent(year_of_list[current_year])
		end
		if data.current_new_moon ~= nil then
	        current_new_moon = data.current_new_moon		
		end
    end

    self:Sync()
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

-- local _advance = nil
-- -- Keep fast-forwarding time
-- _advance = function(inst)
--     inst:DoTaskInTime(1.5, function(inst)
--         TheWorld:PushEvent('ms_nextcycle')
--         _advance(inst)
--     end)
-- end
-- _advance(inst)

--------------------------------------------------------------------------
--[[ END ]]
--------------------------------------------------------------------------
end)