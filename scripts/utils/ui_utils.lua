require "locstrings"

function _eventName(event)
    event = event or 'nil'
    return STRINGS.UI.CUSTOMIZATIONSCREEN[string.upper(event)] or 'nil'
end

function _announce(event)
    local event_string = (GetLocstring(event)
        or GetLocstring('hurray') .. ' ' .. _eventName(event) .. '!')

    if ThePlayer then
        ThePlayer:DoTaskInTime(math.random() * 2, function(inst)
            inst.components.talker:Say(event_string) 
        end)
    end
end

function _playSound(sound, name, volume)
    if ThePlayer then
        ThePlayer.SoundEmitter:PlaySound(sound, name, volume)
    end
end

----------------------------------------------------
-- Seasonal event start sounds

function _winterfeastjingle()
    if TheWorld.ismastersim and not TheWorld:HasTag('cave') then
        TheWorld:PushEvent('ms_forceprecipitation', true)
    end

    if ThePlayer then
        local bell = 'dontstarve/creatures/together/deer/bell'
        local chain = 'dontstarve/creatures/together/deer/chain'
        
        TheWorld:DoTaskInTime(0.0, function() _playSound(bell) end)
        TheWorld:DoTaskInTime(0.3, function() _playSound(bell) end)
        TheWorld:DoTaskInTime(0.6, function() _playSound(bell) end)
        
        TheWorld:DoTaskInTime(1.2, function() _playSound(bell) end)
        TheWorld:DoTaskInTime(1.5, function() _playSound(bell) end)
        TheWorld:DoTaskInTime(1.8, function() _playSound(bell) end)
    end
end

-------------------

function _hallowednightstorm()
    if TheWorld.ismastersim then
        TheWorld:DoTaskInTime(0, function() SpawnPrefab('thunder_close') end)
        TheWorld:DoTaskInTime(1, function() SpawnPrefab('thunder_far') end)
    end

    if ThePlayer then
        ThePlayer:PushEvent('batspooked')
    end
end

-------------------

function _carnivalconfetti()
    if TheWorld.ismastersim then
        for _, player in ipairs(AllPlayers) do
            for i=1,10 do
                TheWorld:DoTaskInTime(math.random() * 4, function() 
                    local angle = math.random() * 2 * math.pi
                    local r = math.random() * 10
                    local x,y,z = player.Transform:GetWorldPosition()
                    local dx = math.sin(angle) * r
                    local dz = math.cos(angle) * r
                    SpawnPrefab('carnival_confetti_fx').Transform:SetPosition(x+dx, y, z+dz) 
                end)
            end
        end

        TheWorld:PushEvent('ms_forceprecipitation', false)
    end

    if ThePlayer then
        _playSound('summerevent2022/carnivalgame_wheelspin/turn_on')
    end            
end

-------------------

function _fireworks()
    -- local boom = "wickerbottom_rework/megaflare/explode"
    local boom = "turnoftides/common/together/miniflare/explode"
    local colors = {
        {r=1.0,g=1.0,b=1.0},
        {r=0.8,g=1.0,b=1.0},
        {r=1.0,g=1.0,b=0.8},
        {r=1.0,g=0.9,b=0.8},
        {r=0.9,g=1.0,b=0.8},
    }

    local function _explode()
        local color = colors[math.random(#colors)]
        ThePlayer:PushEvent("startflareoverlay", color)
        _playSound(boom, nil, 1)
    end
    
    if ThePlayer and not TheWorld:HasTag('cave') then 
        for i=1,5 do TheWorld:DoTaskInTime(math.random() * 5, _explode) end 
    end
end