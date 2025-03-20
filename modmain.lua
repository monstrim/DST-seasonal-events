require = GLOBAL.require

require('netvars')
require('utils/event_utils')
local BatOver = require('widgets/batover')

-- Main mod logic
AddReplicableComponent('eventcalendar')
AddPrefabPostInit('forest_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)
AddPrefabPostInit('cave_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)

-- Trackers for enabling/disabling events
AddPrefabPostInit('carnival_crowkid', GLOBAL._trackCrowkids)
AddPrefabPostInit('goldnugget', GLOBAL._trackNuggies)
AddPrefabPostInit('lucky_goldnugget', GLOBAL._trackNuggies)
for i = GLOBAL.HALLOWEDNIGHTS_TINKET_START, GLOBAL.HALLOWEDNIGHTS_TINKET_END do
    AddPrefabPostInit('trinket_'..tostring(i), GLOBAL._trackTrinkets)
end

-- Init HUD overlay
-- TODO: move to replica somehow?
AddPlayerPostInit(function (player) 
    player:DoTaskInTime(0, function(player)
        if player == GLOBAL.ThePlayer then
            print('[Yearly Seasonal Events] Starting HUD')
            -- HUD for hallows eve
            local hud = player.HUD
            if hud and hud.overlayroot and not hud.batover then
                print('[Yearly Seasonal Events] batover added')
                hud.batover = hud.overlayroot:AddChild(BatOver(player))
            end
        end
    end) 
end)