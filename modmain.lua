require = GLOBAL.require

require('utils/event_utils')

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

AddPlayerPostInit(GLOBAL._setupPlayer)
AddPlayerPostInit(GLOBAL._trackPlayers)

--------------------------------------------------------------------------
-- Cawnival
AddPrefabPostInit('carnival_crowkid', GLOBAL._trackCrowkids)
AddPrefabPostInit('carnival_plaza', GLOBAL._trackPlazas)

--------------------------------------------------------------------------
-- Halloween
AddPrefabPostInit('pumpkin', GLOBAL._trackPumpkins)
AddPrefabPostInit('pumpkin_lantern', GLOBAL._trackPumpkins)

AddPrefabPostInit('livingtree', GLOBAL._setupLivtrees)
AddPrefabPostInit('livingtree_halloween', GLOBAL._trackLivtrees)
AddPrefabPostInit('livingtree_sapling', GLOBAL._trackLivroots)
AddPrefabPostInit('livingtree_root', GLOBAL._trackLivroots)

for i = GLOBAL.HALLOWEDNIGHTS_TINKET_START, GLOBAL.HALLOWEDNIGHTS_TINKET_END do
    AddPrefabPostInit('trinket_'..tostring(i), GLOBAL._trackTrinkets)
end

--------------------------------------------------------------------------
-- Winter's Feast
AddPrefabPostInit('deerclops', GLOBAL._trackDeerclops)
AddPrefabPostInit('dragonfly', GLOBAL._trackDragonfly)
AddPrefabPostInit('bearger', GLOBAL._trackBearger)
AddPrefabPostInit('moose', GLOBAL._trackMoose)
AddPrefabPostInit('klaus', GLOBAL._trackKlaus)

AddPrefabPostInit('deer', GLOBAL._trackDeer)
AddPrefabPostInit('deer_red', GLOBAL._trackDeer)
AddPrefabPostInit('deer_blue', GLOBAL._trackDeer)
AddPrefabPostInit('mossling', GLOBAL._trackMosslings)

--------------------------------------------------------------------------
-- YOTG
AddPrefabPostInit('perdshrine', GLOBAL._trackPerdshrines)
AddPrefabPostInit('perd', GLOBAL._trackPerds)
AddPrefabPostInit('berrybush', GLOBAL._trackBushes)

--------------------------------------------------------------------------
-- YOTP
AddPrefabPostInit('pigking', GLOBAL._trackPigking)

AddPrefabPostInit('goldnugget', GLOBAL._trackNuggies)
AddPrefabPostInit('lucky_goldnugget', GLOBAL._trackNuggies)

--------------------------------------------------------------------------
-- YOTC
AddPrefabPostInit('carrat', GLOBAL._trackCarrats)
AddPrefabPostInit('carrat_planted', GLOBAL._trackCarrats)
AddPrefabPostInit('carrat_ghostracer', GLOBAL._trackGhostracer)
AddPrefabPostInit('beefaloherd', GLOBAL._trackHerds)
AddPrefabPostInit('yotc_carrat_gym_direction', GLOBAL._trackGyms)
AddPrefabPostInit('yotc_carrat_gym_speed', GLOBAL._trackGyms)
AddPrefabPostInit('yotc_carrat_gym_reaction', GLOBAL._trackGyms)
AddPrefabPostInit('yotc_carrat_gym_stamina', GLOBAL._trackGyms)

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
