--------------------------------------------------------------------------
--[[ EventCalendar Replica class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local BatOver = require "widgets/batover"
require "utils/event_utils"
require "utils/ui_utils"

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local SPECIAL_EVENT_KEYS = table.invert(SPECIAL_EVENTS)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local _current_year_event = net_string(inst.GUID, 'seasonalevents._current_year_event', 'currentyearevent_dirty')
local _current_seasonal_event = net_string(inst.GUID, 'seasonalevents._current_seasonal_event', 'currentseasonalevent_dirty')
local _previous_year_event
local _previous_seasonal_event
local _init = net_event(inst.GUID, 'seasonalevents._init')
local _initialized = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function StartEvent(event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE then
        print(string.format('[Yearly Seasonal Events] Attempting start %s', event or 'nil'))
        return
    elseif IsSpecialEventActive(event) then 
        print(string.format('[Yearly Seasonal Events] Event %s already active', event))
        return
    end
    print(string.format('[Yearly Seasonal Events] Starting event %s', event))

    WORLD_EXTRA_EVENTS[event] = true

    local key = SPECIAL_EVENT_KEYS[event]
    if key and TECH[key] then
        TECH[key].SCIENCE = 0
    end

    -- startup event mid-game
    if event == SPECIAL_EVENTS.CARNIVAL then
        _startCarnival()
    elseif event == SPECIAL_EVENTS.HALLOWED_NIGHTS then
        _startHalloween()
    elseif event == SPECIAL_EVENTS.WINTERS_FEAST then
        _startWintersFeast()
    elseif event == SPECIAL_EVENTS.YOTG then
        _startYOTG()
    elseif event == SPECIAL_EVENTS.YOTP then
        _startYOTP()
    elseif event == SPECIAL_EVENTS.YOTC then
        _startYOTC()
    elseif event == SPECIAL_EVENTS.YOTB then
        _startYOTB()
    elseif event == SPECIAL_EVENTS.YOTD then
        _startYOTD()
    elseif event == SPECIAL_EVENTS.YOTS then
        _startYOTS()
    end

    -- fanfarres and announcements
    if _initialized then
        if event == SPECIAL_EVENTS.CARNIVAL then
            _carnivalconfetti()
        elseif event == SPECIAL_EVENTS.HALLOWED_NIGHTS then
            _hallowednightstorm()
        elseif event == SPECIAL_EVENTS.WINTERS_FEAST then
            _winterfeastjingle()
        elseif IS_YEAR_OF_THE_SPECIAL_EVENTS[event] then 
            _fireworks()
        end

        _announce(event)
    end
    
    if TheWorld.components.specialeventsetup then
        TheWorld.components.specialeventsetup:SetupNewSpecialEvent(event)
    end
end

local function StopEvent(event)
    if event == nil or event == "default" or event == SPECIAL_EVENTS.NONE then
        print(string.format('[Yearly Seasonal Events] Attempting stop %s', event or 'nil'))
        return
    elseif not IsSpecialEventActive(event) then 
        print(string.format('[Yearly Seasonal Events] Event %s already inactive', event))
        return
    end
    print(string.format('[Yearly Seasonal Events] Stopping event %s', event))

    WORLD_EXTRA_EVENTS[event] = nil

    local key = SPECIAL_EVENT_KEYS[event]
    if key and TECH[key] then
        TECH[key].SCIENCE = 10
    end

    -- cleanup event
    if event == SPECIAL_EVENTS.CARNIVAL then
        _stopCarnival()
    elseif event == SPECIAL_EVENTS.HALLOWED_NIGHTS then
        _stopHalloween()
    elseif event == SPECIAL_EVENTS.WINTERS_FEAST then
        _stopWintersFeast()
    elseif event == SPECIAL_EVENTS.YOTG then
        _stopYOTG()
    elseif event == SPECIAL_EVENTS.YOTP then
        _stopYOTP()
    elseif event == SPECIAL_EVENTS.YOTC then
        _stopYOTC()
    elseif event == SPECIAL_EVENTS.YOTB then
        _stopYOTB()
    elseif event == SPECIAL_EVENTS.YOTD then
        _stopYOTD()
    elseif event == SPECIAL_EVENTS.YOTS then
        _stopYOTS()
    end
    
    if TheWorld.components.specialeventsetup then
        TheWorld.components.specialeventsetup:ShutdownPrevSpecialEvent(event)
    end
end    

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetYearEvent(value)
    _current_year_event:set(value or SPECIAL_EVENTS.NONE)
end

function self:SetSeasonalEvent(value)
    _current_seasonal_event:set(value or SPECIAL_EVENTS.NONE)
end

function self:WorldEventsInit()
    _init:push()
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnYearDirty(inst)
    local val = _current_year_event:value()

    if val ~= _previous_year_event then
        StopEvent(_previous_year_event)
        StartEvent(val)
    end
    _previous_year_event = val
end

local function OnSeasonDirty(inst)
    local val = _current_seasonal_event:value()

    if val ~= _previous_seasonal_event then
        StopEvent(_previous_seasonal_event)
        StartEvent(val)
    end
    _previous_seasonal_event = val
end

local function OnInit(inst)
    local _year = _current_year_event:value()
    local _season = _current_seasonal_event:value()

    if WORLD_SPECIAL_EVENT then
        if WORLD_SPECIAL_EVENT ~= _year and WORLD_SPECIAL_EVENT ~= _season then
            StopEvent(WORLD_SPECIAL_EVENT)
        end
        WORLD_SPECIAL_EVENT = nil
    end

    for event,_ in pairs(WORLD_EXTRA_EVENTS) do
        if event ~= _year and event ~= _season then
            StopEvent(event)
        end
    end

    if _year then 
        StartEvent(_year)
    end
    if _season then 
        StartEvent(_season)
    end
    _initialized = true
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

_initWintersFeast()

-- Listen for events
inst:ListenForEvent('currentyearevent_dirty', OnYearDirty)
inst:ListenForEvent('currentseasonalevent_dirty', OnSeasonDirty)
inst:ListenForEvent('seasonalevents._init', OnInit)

--------------------------------------------------------------------------
--[[ END ]]
--------------------------------------------------------------------------
end)