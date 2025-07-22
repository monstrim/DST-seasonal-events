--------------------------------------------------------------------------
--[[ EventCalendar class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

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
    },
    
    winter = {
        event = SPECIAL_EVENTS.WINTERS_FEAST, 
        start = 'early', 
        stop = 'mid', 
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
local replica = self.inst.replica.eventcalendar
local shard

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function _yearOfInit()
    -- Add events launched after last update (unpredictable order, but after the existing listed ones)
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
end


local function _checkSeasonalEvents()
    local currentday = TheWorld.state.elapseddaysinseason + 1
    local event_data = seasonal_events[TheWorld.state.season]

    if event_data and (event_data.start_day <= currentday) and (currentday < event_data.stop_day) then
        current_seasonal_event = event_data.event
    else
        current_seasonal_event = nil
    end
end


local function _seasonInit()
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
end

--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:Sync()
    if TheWorld.ismastershard then
        shard:SetYear(current_year)
        shard:SetSeasonalEvent(current_seasonal_event)
    end
    replica:SetYearEvent(year_of_list[current_year])
    replica:SetSeasonalEvent(current_seasonal_event)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnShardSync(src, data)
    current_year = data.current_year
    current_seasonal_event = data.current_seasonal_event
    self:Sync()
end

local function OnCyclesChange(inst)
    _checkSeasonalEvents()
    self:Sync()
end

local function OnMoonChange(inst)
    if TheWorld.state.moonphase == 'new' then
        current_new_moon = current_new_moon + 1
        
        if current_new_moon == 2 then
            current_year = (current_year == #year_of_list) and 1 or current_year + 1
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

function self:Init(_shard)
    -- set shard (this needs a :Init because the shard is initialized after us, and calls this)
    shard = _shard

    if TheWorld.ismastershard then 
        -- Initialize events and seasons
        _yearOfInit()
        _seasonInit()
        _checkSeasonalEvents()
        current_new_moon = 2 --will zero on next winter
        
        -- Listen for events
        inst:WatchWorldState("springlength", function(inst) _seasonInit() end)
        inst:WatchWorldState("summerlength", function(inst) _seasonInit() end)
        inst:WatchWorldState("autumnlength", function(inst) _seasonInit() end)
        inst:WatchWorldState("winterlength", function(inst) _seasonInit() end)

        inst:WatchWorldState("cycles", OnCyclesChange)
        inst:WatchWorldState("season", OnSeasonChange)
        inst:WatchWorldState('moonphase', OnMoonChange)
    
        -- Finally, sync
        self:Sync()
        replica:WorldEventsInit()
    else
        -- Secondary shards just listen to the shard calendar for updates
        inst:ListenForEvent("eventcalendar_sync", OnShardSync)
        inst:DoTaskInTime(1, function() replica:WorldEventsInit() end)
    end
end


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
    if data ~= nil then
		if data.current_year ~= nil then
	        current_year = data.current_year
		end
		if data.current_new_moon ~= nil then
	        current_new_moon = data.current_new_moon		
		end
    end

    shard = TheWorld.shard.components.shard_calendar
    self:Sync()
    replica:WorldEventsInit()
end

--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

-- local _advance = nil
-- local _advance_task = nil
-- -- Keep fast-forwarding time
-- _advance = function(inst)
--     _advance_task = inst:DoTaskInTime(1, function(inst)
--         TheWorld:PushEvent('ms_nextcycle')
--         _advance(inst)
--     end)
-- end
-- _advance(inst)
-- inst:DoTaskInTime(1, function() 
--     TheWorld:ListenForEvent('ms_nextcycle', function()
--         if not _advance_task then _advance(inst) end
--     end)
--     TheWorld:ListenForEvent('master_autosaverupdate', function() 
--         if _advance_task then _advance_task:Cancel() end
--         _advance_task = nil
--     end) 
-- end)

--------------------------------------------------------------------------
--[[ END ]]
--------------------------------------------------------------------------
end)