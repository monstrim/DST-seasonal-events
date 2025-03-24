local BatOver = require "widgets/batover"
local ex_fns = require "prefabs/player_common_extensions"

--------------------------------------------------------------------------

-- Replicates, activates and deactivates all functionalities that would normally be done once at game start,
-- depending on wether the events are active or not, and then left alone throughout the gaming session.

-- The main mod logic is very simple, but here the bulk of the work is done.
-- It's a lot of crap, and there's still a lot to do. Light one up, and let's fucking go.

--------------------------------------------------------------------------

local function createTracker(report)
    local _tracklist = {}

    local function _removeFn(inst)
        if report then print('[Yearly Seasonal Events] untracking '..tostring(inst)) end 
        _tracklist[inst.GUID] = nil
    end

    local function _trackFn(inst)
        if report then print('[Yearly Seasonal Events] tracking '..tostring(inst)) end 
        _tracklist[inst.GUID] = inst
        inst:ListenForEvent('onremove', _removeFn)
    end

    local function _iterateFn(fn)
        local _iterlist = shallowcopy(_tracklist)
        for GUID, inst in pairs(_iterlist) do
            if inst then
                if report then print('[Yearly Seasonal Events] callback on '..tostring(inst)) end 
                fn(inst)
            else
                if report then print('[Yearly Seasonal Events] not found '..GUID) end 
            end
        end
    end

    return _trackFn, _iterateFn
end


local function killWatchers(inst, var)
    if not inst.worldstatewatching then return end
    inst.worldstatewatching[var] = nil
    if next(inst.worldstatewatching) == nil then
        inst.worldstatewatching = nil
    end
    TheWorld.components.worldstate:RemoveWatcher(var, inst)
end


local function killListeners(inst, event, source)
    source = source or inst
    if inst.event_listening[event] then
        inst.event_listening[event][source] = nil
    end
    if source.event_listeners[event] then
        source.event_listeners[event][inst] = nil
    end
end


local function killTimers(name)
    TheWorld.components.worldsettingstimer:StopTimer(name)
    TheWorld.components.worldsettingstimer.timers[name] = nil
end

--------------------------------------------------------------------------
--[[ General ]]
--------------------------------------------------------------------------

_trackPlayers, _iterPlayers = createTracker()

--------------------------------------------------------------------------

function _setupPlayer(player) 
    -- Hallows Eve
    player:DoTaskInTime(0, function(player)
        if player == ThePlayer then
            local hud = player.HUD
            if hud and hud.overlayroot and not hud.batover then
                print('[Yearly Seasonal Events] Starting batover HUD')
                hud.batover = hud.overlayroot:AddChild(BatOver(player))
            end
        end
    end) 
end

--------------------------------------------------------------------------
--[[ Summer Cawnival ]]
--------------------------------------------------------------------------

local carnival_host
_trackCrowkids, _iterCrowkids = createTracker()
_trackPlazas, _iterPlazas = createTracker()

--------------------------------------------------------------------------

-- replicated from prefabs/carnival_plaza
local function _plaza_onactivate(inst, doer)
	if inst._choppeddown then
		return false
	end

	inst.AnimState:PlayAnimation("ringing")
	inst.SoundEmitter:PlaySound("summerevent/plaza/ringing")
	inst.AnimState:PushAnimation("idle", true)
	
	inst.components.activatable.inactive = true
    if TheWorld.components.carnivalevent and IsSpecialEventActive(SPECIAL_EVENTS.CARNIVAL) then --altered to enable/disable
        return TheWorld.components.carnivalevent:SummonHost(inst)
    end
    return false, "NOCARNIVAL"
end

local function _plaza_onremove(inst)
    if TheWorld.components.carnivalevent then
        TheWorld.components.carnivalevent:UnregisterPlaza(inst)
    end
end

--------------------------------------------------------------------------

function _startCarnival()
    if TheWorld.ismastersim then
        if not TheWorld:HasTag('cave') then
            -- carnival host (server)
            if not carnival_host and TheWorld.components.carnivalevent then
                TheWorld.components.carnivalevent:OnPostInit()
                carnival_host = c_find("carnival_host")
            end

            if carnival_host then
                carnival_host.sg:GoToState("glide")
            end
        end

        -- carnival_plaza (server)
        _iterPlazas(function(inst)
            -- these are all added together, so only check for one component...
            if TheWorld.components.carnivalevent and not inst.components.childspawner then
                -- register plaza
                inst:DoTaskInTime(0, function()
                    if TheWorld.components.carnivalevent then
                        TheWorld.components.carnivalevent:RegisterPlaza(inst)
                    end
                end)

                -- add remove callback
                inst:ListenForEvent("onremove", _plaza_onremove)

                -- add spawner
                inst:AddComponent("childspawner")
                inst.components.childspawner.childname = "carnival_crowkid"
                inst.components.childspawner:SetMaxChildren(1)
                inst.components.childspawner.childreninside = 0
                inst.components.childspawner:SetRegenPeriod(4, 0)
                inst.components.childspawner:SetSpawnPeriod(5, 5)
                inst.components.childspawner.allowboats = false
                inst.components.childspawner.spawnradius = {min = 2, max = 6}
                inst.components.childspawner.spawn_height = 30
                inst.components.childspawner.canspawnfn = function() return true end
                inst.components.childspawner:SetSpawnedFn(function(inst, child) child.sg:GoToState("glide") end)
            end

            -- ...but not this one, because we'll remove it later
            if not inst.components.activatable then
                inst:AddComponent("activatable")
                inst.components.activatable.standingaction = true
                inst.components.activatable.OnActivate = _plaza_onactivate
            end

            -- control spawner
            inst.components.childspawner:StartSpawning()
        end)
    end
end

--------------------------------------------------------------------------

function _stopCarnival()
    if TheWorld.ismastersim then
        -- carnival host (server)
        if carnival_host then
            carnival_host.sg:GoToState("flyaway")
            carnival_host:DoTaskInTime(3, carnival_host.Remove)
            carnival_host = nil
        end

        -- crowkids (server)
        _iterCrowkids(function(inst)
            inst.ShouldFlyAway = true 
            inst:DoTaskInTime(3, inst.Remove)
        end)

        -- carnival_plaza (server)
        _iterPlazas(function(inst)
            inst.components.childspawner:StopSpawning()
            inst:RemoveComponent("activatable")
        end)
    end
end

--------------------------------------------------------------------------
--[[ Hallowed Nights ]]
--------------------------------------------------------------------------

_trackTrinkets, _iterTrinkets = createTracker()
_trackPumpkins, _iterPumpkins = createTracker()
_trackLivtrees, _iterLivtrees = createTracker()
_trackLivroots, _iterLivroots = createTracker()

--------------------------------------------------------------------------

-- replicated from prefabs/livingtree_halloween
local function _livingtree_eye(inst)
    if TheWorld.ismastersim then
        if not inst._eyeflames:value() then
            inst.AnimState:SetLightOverride(0)
            inst.SoundEmitter:KillSound("eyeflames")
        else
            inst.AnimState:SetLightOverride(.2)
            if not inst.SoundEmitter:PlayingSound("eyeflames") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_LP", "eyeflames")
                inst.SoundEmitter:SetParameter("eyeflames", "intensity", .2)
            end
        end
        if TheNet:IsDedicated() then
            return
        end
    end

    if inst._eyeflames:value() then
        if inst.eyefxl == nil then
            inst.eyefxl = SpawnPrefab("eyeflame")
            inst.eyefxl.entity:SetParent(inst.entity) --prevent 1st frame sleep on clients
            inst.eyefxl.entity:AddFollower()
            inst.eyefxl.Follower:FollowSymbol(inst.GUID, "eye1", 0, 0, 0)
        end
        if inst.eyefxr == nil then
            inst.eyefxr = SpawnPrefab("eyeflame")
            inst.eyefxr.entity:SetParent(inst.entity) --prevent 1st frame sleep on clients
            inst.eyefxr.entity:AddFollower()
            inst.eyefxr.Follower:FollowSymbol(inst.GUID, "eye2", 0, 0, 0)
        end
    else
        if inst.eyefxl ~= nil then
            inst.eyefxl:Remove()
            inst.eyefxl = nil
        end
        if inst.eyefxr ~= nil then
            inst.eyefxr:Remove()
            inst.eyefxr = nil
        end
    end
end

--------------------------------------------------------------------------

function _setupLivtrees(inst)
    local task = inst:DoTaskInTime(0, function() 
        -- replicated from prefabs/livingtree
        if not inst:HasTag("burnt") and not inst:HasTag("stump") then
            local x, y, z = inst.Transform:GetWorldPosition()
            inst:Remove()
            local new_tree = SpawnPrefab("livingtree_halloween")
            new_tree.Transform:SetPosition(x, y, z)
            if new_tree.components.growable ~= nil then
                new_tree.components.growable:SetStage(#new_tree.components.growable.stages)
            end
        end
    end)

    inst:ListenForEvent('onremove', function() task:Cancel() end)
end

--------------------------------------------------------------------------

function _startHalloween()
    -- livingtrees (common) 
    _iterLivtrees(function(inst)
        inst.AnimState:Show("eye")
        if not inst._eyeflames then
            inst._eyeflames = net_bool(inst.GUID, "livingtree._eyeflames", "eyeflamesdirty")
            inst:ListenForEvent("eyeflamesdirty", _livingtree_eye)
        end
    end) 

    -- livingroots (common)
    _iterLivroots(function(inst) inst.AnimState:Show("eye") end) 

    if TheWorld.ismastersim then
        -- player
        _iterPlayers(function(inst)
            inst:AddComponent("spooked")
            inst:ListenForEvent("spooked", ex_fns.OnSpooked)
        end)

        -- candy for trinkets (server)
        _iterTrinkets(function(inst) inst.components.tradable.halloweencandyvalue = 5 end)

        -- pumpkin perish time (server)
        VEGGIES.pumpkin.perishtime = TUNING.PERISH_PRESERVED
        _iterPumpkins(function(inst) inst.components.perishable:SetPerishTime(inst.prefab == 'pumpkin_lantern' and TUNING.PERISH_SUPERSLOW or TUNING.PERISH_PRESERVED) end)

        -- livingtrees (server)
        _iterLivtrees(function(inst)
            if not inst.components.sanityaura then inst:AddComponent("sanityaura") end
            inst._eyeflames:set(true)
            inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
            inst.components.container.canbeopened = true
        end) 

        -- livingroots (server)
        _iterLivroots(function(inst) 
            if inst.prefab == "livingtree_root" then inst.components.inventoryitem:ChangeImageName("livingtree_root_hallowed_nights") end
        end) 
    end
end

--------------------------------------------------------------------------

function _stopHalloween()
    -- livingtrees (common)
    _iterLivtrees(function(inst) inst.AnimState:Hide("eye") end) 

    -- livingroots (common)
    _iterLivroots(function(inst) inst.AnimState:Hide("eye") end) 

    if TheWorld.ismastersim then
        -- player
        _iterPlayers(function(inst)
            inst:RemoveComponent("spooked")
            inst:RemoveEventCallback("spooked", ex_fns.OnSpooked)
        end)

        -- candy for trinkets (server)
        _iterTrinkets(function(inst) inst.components.tradable.halloweencandyvalue = nil end)

        -- pumpkin perish time (server)
        VEGGIES.pumpkin.perishtime = TUNING.PERISH_MED
        _iterPumpkins(function(inst) inst.components.perishable:SetPerishTime(TUNING.PERISH_MED) end)

        -- livingroots (server)
        _iterLivtrees(function(inst)
            inst._eyeflames:set(false)
            inst.components.sanityaura.aura = 0
            inst.components.container.canbeopened = false
        end) 

        -- livingroots (server)
        _iterLivroots(function(inst)
            if inst.prefab == "livingtree_root" then inst.components.inventoryitem:ChangeImageName("livingtree_root") end
        end) 
    end
end

--------------------------------------------------------------------------
--[[ Winters Feast ]]
--------------------------------------------------------------------------
-- TODO: prefabs/snow - ...whatever, man...

local gingerbreadhunter
local snowballmanager
local klaussackspawner
local KLAUSSACK_TIMERNAME = "klaussack_spawntimer"

_trackDeerclops, _iterDeerclops = createTracker()
_trackDragonfly, _iterDragonfly = createTracker()
_trackBearger, _iterBearger = createTracker()
_trackMoose, _iterMoose = createTracker()
_trackKlaus, _iterKlaus = createTracker()

_trackDeer, _iterDeer = createTracker()
_trackMosslings, _iterMosslings = createTracker()

--------------------------------------------------------------------------

-- replicated from prefabs/deerclops
local function _deerclops_onyule(inst, data)
    if not (inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("waking")) then
        inst.Light:SetIntensity(.6)
        inst.Light:SetRadius(8)
        inst.Light:SetFalloff(3)
        inst.Light:SetColour(1, 0, 0)
    end
end

-- replicated from prefabs/deer
local function _deer_idlesound(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell_idle", nil, volume)
end

local function _deer_bellsound(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/bell", nil, volume)
end

--------------------------------------------------------------------------

function _initWintersFeast()
    if TheWorld.ismastersim then
        gingerbreadhunter = TheWorld.components.gingerbreadhunter
        snowballmanager = TheWorld.components.snowballmanager
        klaussackspawner = TheWorld.components.klaussackspawner
        
        -- gingerbread hunting (server)
        if not TheWorld:HasTag('cave') and not gingerbreadhunter then
            print('[Yearly Seasonal Events] Adding and disabling gingerbreadhunter component.')
            gingerbreadhunter = TheWorld:AddComponent("gingerbreadhunter")
            gingerbreadhunter.__OnIsDay = gingerbreadhunter.OnIsDay
            gingerbreadhunter.OnIsDay = function() end
            gingerbreadhunter.disabled = true
        end
    end
end

--------------------------------------------------------------------------

function _startWintersFeast()
    -- deer common_fn (common)
    _iterDeer(function(inst)
        inst.AnimState:OverrideSymbol("deer_hair", "deer_build", "deer_hair_winter")
        inst.AnimState:OverrideSymbol("swap_neck_collar", "deer_build", "swap_neck_collar_winter")
        inst.AnimState:OverrideSymbol("klaus_deer_chain", "deer_build", "klaus_deer_chain_winter")
        inst.AnimState:OverrideSymbol("deer_chest", "deer_build", "deer_chest_winter")
    end)

    -- deerclops common_fn (common)
    _iterDeerclops(function(inst)
        if not inst.Light then
            inst.entity:AddLight()
            inst.Light:SetIntensity(.6)
            inst.Light:SetRadius(8)
            inst.Light:SetFalloff(3)
            inst.Light:SetColour(1, 0, 0)
        else
            inst.Light:Enable(true)
        end

        inst.build = 'deerclops_yule'
        inst.AnimState:SetBuild(inst.build)
    end)

    -- beager normalfn (common)
    _iterBearger(function(inst) inst.AnimState:SetBuild("bearger_yule") end)

    -- dragonfly (common)
    _iterDragonfly(function(inst) inst.AnimState:SetBuild("dragonfly_yule_build") end)

    -- moose (common)
    _iterMoose(function(inst) inst.AnimState:SetBuild("goosemoose_yule_build") end)

    -- klaus (common)
    _iterKlaus(function(inst)
        inst.AnimState:OverrideSymbol("swap_chain", "klaus_build", "swap_chain_winter")
        inst.AnimState:OverrideSymbol("swap_chain_link", "klaus_build", "swap_chain_link_winter")
        inst.AnimState:OverrideSymbol("swap_chain_lock", "klaus_build", "swap_chain_lock_winter")
        inst.AnimState:OverrideSymbol("swap_klaus_antler", "klaus_build", "swap_klaus_antler_winter")
    end)

    -- mossling (common)
    _iterMosslings(function(inst) inst.AnimState:SetBuild("mossling_yule_build") end)

    if TheWorld.ismastersim then
        -- player_common (server)
        _iterPlayers(function(inst)
            inst:AddComponent("wintertreegiftable")
        end)

        -- gingerbread hunting (server)
        if gingerbreadhunter and gingerbreadhunter.disabled then
            print('[Yearly Seasonal Events] Reenabling gingerbreadhunter component.')
            gingerbreadhunter.OnIsDay = gingerbreadhunter.__OnIsDay
            gingerbreadhunter.__OnIsDay = nil
            gingerbreadhunter.disabled = nil
            -- skip three days to start hunt on day 1
            TheWorld.components.gingerbreadhunter.days = 2
            TheWorld.components.gingerbreadhunter:OnIsDay()
        elseif gingerbreadhunter then
            print('[Yearly Seasonal Events] gingerbreadhunter already enabled.')
        end

        -- deerclops common_fn (server)
        _iterDeerclops(function(inst)
            if inst.components.timer == nil then 
                print('[Yearly Seasonal Events] adding timer to deerclops.')
                inst:AddComponent('timer') 
            end
            inst.yule = true
            inst.haslaserbeam = true
            inst:ListenForEvent("newstate", _deerclops_onyule)
        end)

        -- klaus (server)
        _iterKlaus(function(inst)
            inst.components.lootdropper:AddChanceLoot("winter_food3", 1)
            inst.components.lootdropper:AddChanceLoot("winter_food3", 1)
        end)
        
        -- klaussackspawner (server)
        if klaussackspawner then
            killTimers(KLAUSSACK_TIMERNAME)
            killWatchers(klaussackspawner, 'iswinter')
            klaussackspawner:OnPostInit()
        end

        -- deer common_fn (server)
        _iterDeer(function(inst)
            inst.DoBellSound = _deer_idlesound
            inst.DoBellIdleSound = _deer_bellsound
        end)
    end
end

--------------------------------------------------------------------------

function _stopWintersFeast()
    -- deerclops common_fn (common)
    _iterDeerclops(function(inst)
        inst.Light:Enable(false)

        inst.build = 'deerclops_build'
        inst.AnimState:SetBuild(inst.build)
    end)

    -- beager normalfn (server)
    _iterBearger(function(inst) inst.AnimState:SetBuild("bearger_build") end)

    -- dragonfly (common)
    _iterDragonfly(function(inst) inst.AnimState:SetBuild("dragonfly_build") end)

    -- moose (common)
    _iterMoose(function(inst) inst.AnimState:SetBuild("goosemoose_build") end)

    -- klaus (common)
    _iterKlaus(function(inst)
        inst.AnimState:ClearOverrideSymbol("swap_chain", "klaus_build", "swap_chain_winter")
        inst.AnimState:ClearOverrideSymbol("swap_chain_link", "klaus_build", "swap_chain_link_winter")
        inst.AnimState:ClearOverrideSymbol("swap_chain_lock", "klaus_build", "swap_chain_lock_winter")
        inst.AnimState:ClearOverrideSymbol("swap_klaus_antler", "klaus_build", "swap_klaus_antler_winter")
    end)

    -- deer_common (common)
    _iterDeer(function(inst)
        inst.AnimState:ClearOverrideSymbol("deer_hair", "deer_build", "deer_hair_winter")
        inst.AnimState:ClearOverrideSymbol("swap_neck_collar", "deer_build", "swap_neck_collar_winter")
        inst.AnimState:ClearOverrideSymbol("klaus_deer_chain", "deer_build", "klaus_deer_chain_winter")
        inst.AnimState:ClearOverrideSymbol("deer_chest", "deer_build", "deer_chest_winter")
    end)

    -- mossling (common)
    _iterMosslings(function(inst) inst.AnimState:SetBuild("mossling_build") end)

    if TheWorld.ismastersim then
        -- player_common (server)
        _iterPlayers(function(inst) inst:RemoveComponent("wintertreegiftable") end)

        -- gingerbread hunting (server)
        if gingerbreadhunter and gingerbreadhunter.disabled then
            print('[Yearly Seasonal Events] Gingerbreadhunter already disabled.')
        elseif gingerbreadhunter then
            print('[Yearly Seasonal Events] Disabling gingerbreadhunter component.')
            gingerbreadhunter.__OnIsDay = gingerbreadhunter.OnIsDay
            gingerbreadhunter.OnIsDay = function() end
            if gingerbreadhunter.newhunttask then
                gingerbreadhunter.newhunttask:Cancel()
                gingerbreadhunter.newhunttask = nil
            end
            gingerbreadhunter.disabled = true
        end
        
        -- snowballs (server)
        if snowballmanager and snowballmanager.enabled == true then
            print('[Yearly Seasonal Events] Removing snowball spawning.')
            snowballmanager:SetEnabled(false)
        end

        -- deerclops common_fn (server)
        _iterDeerclops(function(inst)
            inst.yule = nil
            inst.haslaserbeam = nil
            killListeners(inst, "newstate") -- might be our replicated _listener or the original (local) callback
        end)

        -- klaus (server)
        _iterKlaus(function(inst)
            inst.components.lootdropper:SetLoot(inst.components.lootdropper.loots)
        end)
        
        -- klaussackspawner (server)
        if klaussackspawner then
            killTimers(KLAUSSACK_TIMERNAME)
            killWatchers(klaussackspawner, 'iswinter')
            klaussackspawner:OnPostInit()
        end

        -- deer common_fn (server)
        _iterDeer(function(inst)
            inst.DoBellSound = function() end
            inst.DoBellIdleSound = function() end
        end)
    end
end

--------------------------------------------------------------------------
--[[ Year of the Gobbler ]]
--------------------------------------------------------------------------
-- TODO: prefabs/berrybush (server) - add/kill , change callbacks... but maybe dont (trigger invalid??)
-- TODO: prefabs/perdshrine (server) - replicate functions, callback, watcher... but maybe dont (trigger invalid??)

_trackPerds, _iterPerds = createTracker()

--------------------------------------------------------------------------

-- replicated from prefabs/perd
local PERD_TAGS = { "perd" }
local function _yotg_perd_onattacked(inst)
    local tochain = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, 14, PERD_TAGS)) do
        if v.seekshrine then
            v.seekshrine = nil
            -- inst:RemoveEventCallback("attacked", OnAttacked)
            killListeners(inst, "attacked") -- the callback might be the (local) original or our replicated one
            if v ~= inst then
                table.insert(tochain, v)
            end
        end
    end
    for i, v in ipairs(tochain) do
        _yotg_perd_onattacked(v)
    end
end

local function _yotg_perd_onaeat(inst, food)
    --eat off the ground, not picked berries
    if food.components.inventoryitem ~= nil and
        not food.components.inventoryitem:IsHeld() and
        not inst.components.timer:TimerExists("offeringcooldown") then
        inst.sg.statemem.dropoffering = true
        if not inst.seekshrine then
            inst.seekshrine = true
            inst:ListenForEvent("attacked", _yotg_perd_onattacked)
        end
    end
end

local function _yotg_perd_lootsetfn(lootdropper)
    if not lootdropper.inst.components.timer:TimerExists("offeringcooldown") then
        lootdropper:AddChanceLoot("redpouch", .1)
    end
end

local function _yotg_perd_dropoffering(inst)
    if not inst.components.timer:TimerExists("offeringcooldown") then
        inst.components.timer:StartTimer("offeringcooldown", TUNING.TOTAL_DAY_TIME)
        LaunchAt(SpawnPrefab("redpouch"), inst, inst:GetNearestPlayer(true) or inst:GetNearestPlayer(), .5, 1, .5)
    end
end

--------------------------------------------------------------------------

function _startYOTG()
    -- Perds (common)
    _iterPerds(function(inst) inst:AddTag("perd") end)

    if TheWorld.ismastersim then
        -- Perds (server)
        _iterPerds(function(inst)
            inst:AddComponent("timer")
            inst.components.eater:SetOnEatFn(_yotg_perd_onaeat)
            inst.components.lootdropper:SetLootSetupFn(_yotg_perd_lootsetfn)
            inst.DropOffering = _yotg_perd_dropoffering
            inst.seekshrine = true
            inst:ListenForEvent("attacked", _yotg_perd_onattacked)
        end)
    end
end

--------------------------------------------------------------------------

function _stopYOTG()
    -- Perds (common)
    _iterPerds(function(inst) inst:RemoveTag("perd") end)

    if TheWorld.ismastersim then
        -- Perds (server)
        _iterPerds(function(inst)
            inst:RemoveComponent("timer")
            inst.components.eater:SetOnEatFn(nil)
            inst.components.lootdropper:SetLootSetupFn(nil)
            inst.DropOffering = nil
            inst.seekshrine = nil
            -- inst:RemoveEventCallback("attacked", _yotg_perd_onattacked)
            killListeners(inst, "attacked") -- the callback might be the (local) original or our replicated one
        end)
    end
end

--------------------------------------------------------------------------
--[[ Year of the Varg ]]
--------------------------------------------------------------------------
-- Nothing here??

--------------------------------------------------------------------------
--[[ Year of the Pig King ]]
--------------------------------------------------------------------------

_trackNuggies, _iterNuggies = createTracker()
_trackPigking, _iterPigking = createTracker()

--------------------------------------------------------------------------

function _startYOTP()
    -- gold nuggets and lucky gold nuggets
    _iterNuggies(function(inst) 
        if inst.prefab == 'goldnugget' then inst:RemoveTag("minigameitem")
        elseif inst.prefab == 'lucky_goldnugget' then inst:AddTag("minigameitem")
        else print('[Yearly Special Events] Not a goldnugget')
        end
    end)

    -- pig king
    _iterPigking(function(inst) inst.AnimState:AddOverrideBuild("Pig_King_elite_build") end)
end

--------------------------------------------------------------------------

function _stopYOTP()
    -- gold nuggets and lucky gold nuggets
    _iterNuggies(function(inst) 
        if inst.prefab == 'goldnugget' then inst:AddTag("minigameitem")
        elseif inst.prefab == 'lucky_goldnugget' then inst:RemoveTag("minigameitem")
        else print('[Yearly Special Events] Not a goldnugget')
        end
    end)

    -- pig king
    _iterPigking(function(inst) inst.AnimState:ClearOverrideBuild("Pig_King_elite_build") end)
end

--------------------------------------------------------------------------
--[[ Year of the Carrat ]]
--------------------------------------------------------------------------
-- TODO: prefabs/carrat fn (common) - replicate get_dropaction_string
-- TODO: prefabs/carrat fn (server) - replicate train funcs, replicate callbacks, add/kill listeners
-- TODO: prefabs/beefaloherd fn - replicate carrat spawner and add/remove listen
-- TODO: prefabs/rat_gym (server) - add component, replicate callbacks

_trackCarrats, _iterCarrats = createTracker()
_trackGhostracer, _iterGhostracer = createTracker()

--------------------------------------------------------------------------

function _startYOTC()
    -- carrats (common)
    _iterCarrats(function(inst)
        inst.AnimState:AddOverrideBuild("redpouch_yotc")
        if not inst:HasTag("_named") then inst:AddTag("_named") end
    end)

    -- carrat ghostracer
    _iterGhostracer(function(inst) inst.AnimState:AddOverrideBuild("redpouch_yotc") end)

    if TheWorld.ismastersim then
        -- carrats (server)
       _iterCarrats(function(inst)
            inst:AddComponent("named")
        end)
    end
end

--------------------------------------------------------------------------

function _stopYOTC()
    -- carrats (common)
    _iterCarrats(function(inst)
        inst.AnimState:ClearOverrideBuild("redpouch_yotc")
        if inst:HasTag("_named") then inst:RemoveTag("_named") end
    end)

    -- carrat ghostracer
    _iterGhostracer(function(inst) inst.AnimState:ClearOverrideBuild("redpouch_yotc") end)

    if TheWorld.ismastersim then
        -- carrats (server)
       _iterCarrats(function(inst)
            inst:RemoveComponent("named")
        end)
    end
end

--------------------------------------------------------------------------
--[[ Year of the Beefalo ]]
--------------------------------------------------------------------------
-- TODO: playercommon fn (common) - add/remove netint, replicate and do task... or not (skins?)

_trackPigmen, _iterPigmen = createTracker()

--------------------------------------------------------------------------

function _startYOTB()
    -- pigmen
    _iterPigmen(function(inst) inst.AnimState:AddOverrideBuild("pigman_yotb") end)
end

--------------------------------------------------------------------------

function _stopYOTB()
    -- pigmen
    _iterPigmen(function(inst) inst.AnimState:ClearOverrideBuild("pigman_yotb") end)
end

--------------------------------------------------------------------------
--[[ Year of the Catcoon ]]
--------------------------------------------------------------------------
-- TODO: prefabs/kitcoon - replicate and add/remove callback

--------------------------------------------------------------------------
--[[ Year of the Bunnyman ]]
--------------------------------------------------------------------------
-- Nothing here??

--------------------------------------------------------------------------
--[[ Year of the Dragonfly ]]
--------------------------------------------------------------------------

function _startYOTD()
    if TheWorld.ismastersim then
        TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=1})
    end
end

function _stopYOTD()
    if TheWorld.ismastersim then
        TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=0})
    end
end

--------------------------------------------------------------------------
--[[ Year of the Depth Worm ]]
--------------------------------------------------------------------------

_trackWorms, _iterWorms = createTracker()
_trackShadows, _iterShadows = createTracker()

-- replicated from prefabs/worm
local function _worm_lootsetfn(lootdropper)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
end

-- replicated from prefabs/shadowthrall_mouth
local function _shadowthrall_lootsetfn(lootdropper)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)
    lootdropper:AddChanceLoot("lucky_goldnugget", 1)    
end

--------------------------------------------------------------------------

function _startYOTS()
    if TheWorld.ismastersim then
        -- depth worm
        _iterWorms(function(inst) inst.components.lootdropper:SetLootSetupFn(_worm_lootsetfn) end)

        -- shadowthrall_mouth
        _iterShadows(function(inst) inst.components.lootdropper:SetLootSetupFn(_shadowthrall_lootsetfn) end)
    end
end

--------------------------------------------------------------------------

function _stopYOTS()
    if TheWorld.ismastersim then
        -- depth worm
        _iterWorms(function(inst) inst.components.lootdropper:SetLootSetupFn() end)

        -- shadowthrall_mouth
        _iterShadows(function(inst) inst.components.lootdropper:SetLootSetupFn() end)
    end
end