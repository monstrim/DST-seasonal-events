require = GLOBAL.require

require('utils/event_utils')
local BatOver = require('widgets/batover')

--------------------------------------------------------------------------
--[[ Main mod logic ]]
--------------------------------------------------------------------------
AddReplicableComponent('eventcalendar')
AddPrefabPostInit('shard_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('shard_calendar') end end)
AddPrefabPostInit('forest_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)
AddPrefabPostInit('cave_network', function (inst) if GLOBAL.TheWorld.ismastersim then inst:AddComponent('eventcalendar') end end)

--------------------------------------------------------------------------
--[[ Trackers for enabling/disabling events ]]
--------------------------------------------------------------------------
-- Cawnival
AddPrefabPostInit('carnival_crowkid', GLOBAL._trackCrowkids)

--------------------------------------------------------------------------
-- Halloween
AddPrefabPostInit('pumpkin', GLOBAL._trackPumpkins)
AddPrefabPostInit('pumpkin_lantern', GLOBAL._trackPumpkins)

AddPrefabPostInit('livingtree_halloween', GLOBAL._trackLivtrees)
AddPrefabPostInit('livingtree_sapling', GLOBAL._trackLivroots)
AddPrefabPostInit('livingtree_root', GLOBAL._trackLivroots)

for i = GLOBAL.HALLOWEDNIGHTS_TINKET_START, GLOBAL.HALLOWEDNIGHTS_TINKET_END do
    AddPrefabPostInit('trinket_'..tostring(i), GLOBAL._trackTrinkets)
end

--------------------------------------------------------------------------
-- Winter's Feast
AddPrefabPostInit('deerclops', GLOBAL._trackDeerclops)

AddPrefabPostInit('deer', GLOBAL._trackDeer)
AddPrefabPostInit('deer_red', GLOBAL._trackDeer)
AddPrefabPostInit('deer_blue', GLOBAL._trackDeer)

--------------------------------------------------------------------------
-- YOTG
AddPrefabPostInit('perd', GLOBAL._trackPerds)

--------------------------------------------------------------------------
-- YOTP
AddPrefabPostInit('pigking', GLOBAL._trackPigking)

AddPrefabPostInit('goldnugget', GLOBAL._trackNuggies)
AddPrefabPostInit('lucky_goldnugget', GLOBAL._trackNuggies)

--------------------------------------------------------------------------
-- YOTC
AddPrefabPostInit('carrat', GLOBAL._trackCarrats)
AddPrefabPostInit('carrat_ghostracer', GLOBAL._trackGhostracer)

--------------------------------------------------------------------------
-- YOTB
AddPrefabPostInit('pigman', GLOBAL._trackPigmen)
AddPrefabPostInit('pigguard', GLOBAL._trackPigmen)
AddPrefabPostInit('moonpig', GLOBAL._trackPigmen)

AddPrefabPostInit('merm', GLOBAL._trackPigmen)
AddPrefabPostInit('mermguard', GLOBAL._trackPigmen)
AddPrefabPostInit('merm_shadow', GLOBAL._trackPigmen)
AddPrefabPostInit('mermguard_shadow', GLOBAL._trackPigmen)
AddPrefabPostInit('merm_lunar', GLOBAL._trackPigmen)
AddPrefabPostInit('mermguard_lunar', GLOBAL._trackPigmen)

--------------------------------------------------------------------------
-- YOTS
AddPrefabPostInit('worm', GLOBAL._trackWorms)
AddPrefabPostInit('shadowthrall_mouth', GLOBAL._trackShadows)

--------------------------------------------------------------------------
--[[ Init HUD overlay ]]
--------------------------------------------------------------------------
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