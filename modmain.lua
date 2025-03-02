require = GLOBAL.require

-- modimport("debug_funcs")
require("netvars")
local BatOver = require "widgets/batover"

AddReplicableComponent("eventcalendar")

AddPrefabPostInit('forest_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)
AddPrefabPostInit('cave_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)

-- route flareoverlay and batspooked events from server to client
AddPlayerPostInit(function (player) player:DoTaskInTime(0, 
    function(player)
        _spook_trigger = GLOBAL.net_event(player.GUID, 'seasonalevents._spook_trigger')
        _flare_trigger = GLOBAL.net_event(player.GUID, 'seasonalevents._flare_trigger')
        _flare_r = GLOBAL.net_float(player.GUID, 'seasonalevents._flare_r')
        _flare_g = GLOBAL.net_float(player.GUID, 'seasonalevents._flare_g')
        _flare_b = GLOBAL.net_float(player.GUID, 'seasonalevents._flare_b')

        if player == GLOBAL.ThePlayer then
            -- setup listening on client

            -- HUD for hallows eve
            local hud = player.HUD
            if hud and hud.overlayroot and not hud.batover then
                hud.batover = hud.overlayroot:AddChild(BatOver(player))
            end

            player:ListenForEvent('seasonalevents._flare_trigger', function(player) 
                data = {
                    r = _flare_r:value(),
                    g = _flare_g:value(),
                    b = _flare_b:value(),
                }
                player:PushEvent('startflareoverlay', data)
            end)

            player:ListenForEvent('seasonalevents._spook_trigger', function(player) 
                player:PushEvent('batspooked')
            end)
        else
            -- setup triggering on server
            player:ListenForEvent('startflareoverlay', function(player, data) 
                _flare_r:set(data.r)
                _flare_g:set(data.g)
                _flare_b:set(data.b)
                _flare_trigger:push()
            end)

            player:ListenForEvent('batspooked', function(player) 
                _spook_trigger:push()
            end)
        end
    end) 
end)