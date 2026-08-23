--------------------------------------------------------------------------
--[[ Shard Calendar class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

-- Public
self.inst = inst

-- Private
local _current_year = net_ushortint(inst.GUID, 'seasonalevents._current_year', 'calendardirty')
local _current_seasonal_event = net_string(inst.GUID, 'seasonalevents._current_seasonal_event', 'calendardirty')
local calendar = TheWorld.net.components.eventcalendar

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:SetYear(current_year)
    _current_year:set(current_year)
end

function self:SetSeasonalEvent(current_seasonal_event)
    _current_seasonal_event:set(current_seasonal_event or SPECIAL_EVENTS.NONE)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnCalendarDirty()
    calendar.inst:PushEvent('eventcalendar_sync', {
        current_year = _current_year:value(),
        current_seasonal_event = _current_seasonal_event:value()
    })
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

if TheWorld.net.components.eventcalendar then
    TheWorld.net.components.eventcalendar:Init(self)

    -- Listen for events
    inst:ListenForEvent('calendardirty', OnCalendarDirty)
end

--------------------------------------------------------------------------
--[[ END ]]
--------------------------------------------------------------------------
end)