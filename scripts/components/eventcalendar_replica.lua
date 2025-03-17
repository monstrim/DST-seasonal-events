--------------------------------------------------------------------------
--[[ EventCalendar Replica class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

local BatOver = require "widgets/batover"
-- ui_utils

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

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function EnableEvent(event)
    if event == nil or event == SPECIAL_EVENTS.NONE then
        return
    end
    WORLD_EXTRA_EVENTS[event] = true
    local key = SPECIAL_EVENT_KEYS[event]
    if key and TECH[key] then
        TECH[key].SCIENCE = 0
    end
end

local function DisableEvent(event)
    if event == nil or event == SPECIAL_EVENTS.NONE then
        return
    end
    WORLD_EXTRA_EVENTS[event] = nil
    local key = SPECIAL_EVENT_KEYS[event]
    if key and TECH[key] then
        TECH[key].SCIENCE = 10
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

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnYearDirty(inst)
    local val = _current_year_event:value()

    if val and val ~= _previous_year_event then
        DisableEvent(_previous_year_event)
        EnableEvent(val)
    end
    _previous_year_event = val
end

local function OnSeasonDirty(inst)
    local val = _current_seasonal_event:value()

    if _previous_seasonal_event and _previous_seasonal_event ~= val then
        DisableEvent(_previous_seasonal_event)
    end

    if val and val ~= _previous_seasonal_event then
        EnableEvent(val)
    end
    _previous_seasonal_event = val
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

-- Let's try to have the main component do that instead (so it correctly stops)
-- -- Disable all extra events so mod will use them
-- for k,v in pairs(WORLD_EXTRA_EVENTS) do WORLD_EXTRA_EVENTS[k] = nil end

-- -- Disable, unless the main component is going to need it
-- if not (TheWorld.ismastersim and IS_YEAR_OF_THE_SPECIAL_EVENTS[WORLD_SPECIAL_EVENT]) then
--     WORLD_SPECIAL_EVENT = SPECIAL_EVENTS.NONE
-- end

-- Listen for events
inst:ListenForEvent('currentyearevent_dirty', OnYearDirty)
inst:ListenForEvent('currentseasonalevent_dirty', OnSeasonDirty)

--------------------------------------------------------------------------
--[[ END ]]
--------------------------------------------------------------------------
end)