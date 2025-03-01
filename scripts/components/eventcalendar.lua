--------------------------------------------------------------------------
--[[ EventCalendar class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

require "ui_utils"
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
local carnival_host

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function _startCrow()
    if not carnival_host then
        TheWorld.components.carnivalevent:OnPostInit()
        carnival_host = GLOBAL.c_find("carnival_host")
    end

    if carnival_host then
        carnival_host.sg:GoToState("glide")
    end
end


local function _stopCrow()
    if carnival_host then
        carnival_host.sg:GoToState("flyaway")
        carnival_host:DoTaskInTime(3, carnival_host.Remove)
    end
end


local function _startDragonflyPrize()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=1})
end


local function _stopDragonflyPrize()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=o})
end


--------------------------------------------------------------------------

local function StartEvent(event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE then
        print(string.format('Event %s', event or 'nil'))
        return
    elseif IsSpecialEventActive(event) then 
        print(string.format('Event %s already active', event))
        return
    end

    -- startup event mid-game
    if event == SPECIAL_EVENTS.CARNIVAL then
        _startCrow()
    elseif event == SPECIAL_EVENTS.YOTD then
        _startDragonflyPrize()
    elseif TheWorld.components.specialeventsetup ~= nil then
        TheWorld.components.specialeventsetup:SetupNewSpecialEvent(event)
    else
        print('TheWorld.components.specialeventsetup not found')
    end
end

local function StopEvent(event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE or not IsSpecialEventActive(event) then 
        return
    end
    
    -- cleanup event
    if event == SPECIAL_EVENTS.CARNIVAL then
        _stopCrow()
    elseif event == SPECIAL_EVENTS.YOTD then
        _stopDragonflyPrize()
    elseif TheWorld.components.specialeventsetup ~= nil then
        TheWorld.components.specialeventsetup:ShutdownPrevSpecialEvent(event)
    else
        print('TheWorld.components.specialeventsetup not found')
    end
end

--------------------------------------------------------------------------

local function _seasonInit ()
    local lengths = {
        spring = TheWorld.state.springlength,
        summer = TheWorld.state.summerlength,
        autumn = TheWorld.state.autumnlength,
        winter = TheWorld.state.winterlength,
    }
    local quarters = {
        early = function (season_length) return math.ceil(season_length/4) end,
        mid = function (season_length) return math.ceil(season_length/2) end,
        late = function (season_length) return math.ceil(season_length*3/4) end,
    }
    for season, data in pairs(seasonal_events) do
        data.start_day = quarters[data.start](lengths[season])
        data.stop_day = quarters[data.stop](lengths[season])
    end
end


local function _checkSeasonalEvents()
    local currentday = TheWorld.state.elapseddaysinseason + 1
    local event_data = seasonal_events[TheWorld.state.season]

    if event_data and (event_data.start_day <= currentday) and (currentday <= event_data.stop_day) then
        if not IsSpecialEventActive(event_data.event) then
            StopEvent(current_seasonal_event)
            current_seasonal_event = event_data.event
            StartEvent(current_seasonal_event)
            if event_data.fanfarre then event_data.fanfarre() end
            _announce('Happy %s!', current_seasonal_event)
            self:Sync()
        end
    else
        if current_seasonal_event then
            StopEvent(current_seasonal_event)
            _announce('%s is over.', current_seasonal_event)
            current_seasonal_event = nil
            self:Sync()
        end
    end
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
        
        if current_new_moon >= 2 then
            StopEvent(year_of_list[current_year])
            current_year = (current_year == #year_of_list) and 1 or current_year + 1
            StartEvent(year_of_list[current_year])
            _fireworks()
            _announce('Happy %s!', year_of_list[current_year])
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
print('[Yearly Seasonal Events] INITIALIZING MAIN COMPONENT')

-- Events launched after last update
for v,_ in pairs(IS_YEAR_OF_THE_SPECIAL_EVENTS) do
    if not year_of_set[v] then
        print('[Yearly Seasonal Events] adding ' .. v)
        table.insert(year_of_list, v)
        year_of_set[v] = true
    end
end

--TODO: check if winter available
new_year_season = 'winter' or 'TODO'

-- If a Year Of is currently active, set it to current year, otherwise begin at the last
if WORLD_SPECIAL_EVENT and IS_YEAR_OF_THE_SPECIAL_EVENTS[WORLD_SPECIAL_EVENT] then
    current_year = table.invert(year_of_list)[WORLD_SPECIAL_EVENT]
else
    current_year = #year_of_list
end
WORLD_SPECIAL_EVENT = SPECIAL_EVENTS.NONE
StartEvent(year_of_list[current_year])

-- Listen for events
inst:WatchWorldState("cycles", OnCyclesChange)
inst:WatchWorldState("season", OnSeasonChange)
inst:WatchWorldState('moonphase', OnMoonChange)
inst:WatchWorldState("springlength", function(inst) _seasonInit() end)
inst:WatchWorldState("summerlength", function(inst) _seasonInit() end)
inst:WatchWorldState("autumnlength", function(inst) _seasonInit() end)
inst:WatchWorldState("winterlength", function(inst) _seasonInit() end)

-- Finally, initialize events and sync
current_new_moon = 2 --will zero on next winter
_seasonInit()
_checkSeasonalEvents()
self:Sync()

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
    data.current_year = current_year
    data.current_new_moon = current_new_moon
    data.current_seasonal_event = current_seasonal_event
    return data
end

function self:OnLoad(data)
    if data ~= nil then
		if data.current_year ~= nil then
	        current_year = data.current_year		
		end
		if data.current_new_moon ~= nil then
	        current_new_moon = data.current_new_moon		
		end
		if data.current_seasonal_event ~= nil then
	        current_seasonal_event = data.current_seasonal_event		
		end
    end
    self:Sync()
end

--------------------------------------------------------------------------
--[[ END ]]
--------------------------------------------------------------------------
end)