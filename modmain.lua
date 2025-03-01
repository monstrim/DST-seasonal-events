require = GLOBAL.require

-- Decomment to use
modimport("debug_funcs")
require("netvars")

AddReplicableComponent("eventcalendar")

AddPrefabPostInit('forest_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)
AddPrefabPostInit('cave_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)

-- route flareoverlay events from server to client
AddPlayerPostInit(function (player) player:DoTaskInTime(0, 
    function(player)
        _flare_trigger = GLOBAL.net_event(player.GUID, 'seasonalevents._flare_trigger')
        _flare_r = GLOBAL.net_float(player.GUID, 'seasonalevents._flare_r')
        _flare_g = GLOBAL.net_float(player.GUID, 'seasonalevents._flare_g')
        _flare_b = GLOBAL.net_float(player.GUID, 'seasonalevents._flare_b')

        if player ~= GLOBAL.ThePlayer then
            player:ListenForEvent('startflareoverlay', function(player, data) 
                _flare_r:set(data.r)
                _flare_g:set(data.g)
                _flare_b:set(data.b)
                _flare_trigger:push()
            end)
        else
            player:ListenForEvent('seasonalevents._flare_trigger', function(player) 
                data = {
                    r = _flare_r:value(),
                    g = _flare_g:value(),
                    b = _flare_b:value(),
                }
                player:PushEvent('startflareoverlay', data)
            end)
        end
    end) 
end)