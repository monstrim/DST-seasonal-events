require "locstrings"

function _eventName(event)
    event = event or 'nil'
    return STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(event)] or 'nil'
end

function _announce(event)
    for i,v in ipairs(AllPlayers) do 
        local event_string = (GetLocstring(event)
            or GetLocstring('hurray') .. ' ' .. _eventName(event) .. '!')
        v:DoTaskInTime(math.random() * 2, function(v)
            v.components.talker:Say(event_string) 
        end)
    end
end

function _playSound(sound, name, volume)
    --TODO: test difference between TheWorld and ThePlayer in multiplayer
    for i,v in ipairs(AllPlayers) do v.SoundEmitter:PlaySound(sound, name, volume) end
end

----------------------------------------------------
-- Seasonal event start sounds

function _winterfeastjingle()
    local bell = 'dontstarve/creatures/together/deer/bell'
    local chain = 'dontstarve/creatures/together/deer/chain'
    
    TheWorld:DoTaskInTime(0.0, function() _playSound(bell) end)
    TheWorld:DoTaskInTime(0.3, function() _playSound(bell) end)
    TheWorld:DoTaskInTime(0.6, function() _playSound(bell) end)
    
    TheWorld:DoTaskInTime(1.2, function() _playSound(bell) end)
    TheWorld:DoTaskInTime(1.5, function() _playSound(bell) end)
    TheWorld:DoTaskInTime(1.8, function() _playSound(bell) end)

    TheWorld:PushEvent('ms_forceprecipitation', true)
end

-------------------

function _hallowednightstorm()
    TheWorld:DoTaskInTime(1, function() SpawnPrefab('thunder_close') end)
    TheWorld:DoTaskInTime(2, function() SpawnPrefab('thunder_far') end)
    TheWorld:DoTaskInTime(3, function() SpawnPrefab('thunder_close') end)
    TheWorld:DoTaskInTime(5, function() SpawnPrefab('thunder_far') end)
    TheWorld:DoTaskInTime(8, function() SpawnPrefab('thunder_close') end)
    TheWorld:DoTaskInTime(13, function() SpawnPrefab('thunder_far') end)

    for i,v in ipairs(AllPlayers) do v:PushEvent('batspooked') end
end

-------------------

function _fireworks()
    local boom = "wickerbottom_rework/megaflare/explode"
    local colors = {
        {r=1.0,g=1.0,b=1.0},
        {r=0.8,g=1.0,b=1.0},
        {r=1.0,g=1.0,b=0.8},
        {r=1.0,g=0.9,b=0.8},
        {r=0.9,g=1.0,b=0.8},
    }

    local function _explode()
        local color = colors[math.random(#colors)]
        for i, v in ipairs(AllPlayers) do v:PushEvent("startflareoverlay", color) end
        _playSound(boom, nil, 1)    
    end
    
    TheWorld:DoTaskInTime(2, _explode)
    TheWorld:DoTaskInTime(5, _explode)
    TheWorld:DoTaskInTime(7, _explode)
    TheWorld:DoTaskInTime(12, _explode)
    TheWorld:DoTaskInTime(19, _explode)
end