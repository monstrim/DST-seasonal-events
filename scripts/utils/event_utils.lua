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

    -- be careful not to add/remove items DURING iter, I guess?
    local function _iterateFn(fn)
        for GUID, inst in pairs(_tracklist) do
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


local function killListeners(inst, event, source)
    source = source or inst
    if inst.event_listening[event] then
        inst.event_listening[event][source] = nil
    end
    if source.event_listeners[event] then
        source.event_listeners[event][inst] = nil
    end
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
-- TODO: prefabs/livingtree fn (server) - change for livingtree_haloween prefab (can be done regardless of halloween status)
-- TODO: prefabs/livingtree_halloween fn (common) - add net_bool, replicate callback, add/remove listeners
-- TODO: prefabs/livingtree_halloween fn (server) - add component
-- TODO: prefabs/playercommon fn - add spook component, add/remove listen

_trackTrinkets, _iterTrinkets = createTracker()
_trackPumpkins, _iterPumpkins = createTracker()
_trackLivtrees, _iterLivtrees = createTracker()
_trackLivroots, _iterLivroots = createTracker()

--------------------------------------------------------------------------

function _startHalloween()
    if TheWorld.ismastersim then
        -- candy for trinkets (server)
        _iterTrinkets(function(inst) inst.components.tradable.halloweencandyvalue = 5 end)

        -- pumpkin perish time (server)
        VEGGIES.pumpkin.perishtime = TUNING.PERISH_PRESERVED
        _iterPumpkins(function(inst) inst.components.perishable:SetPerishTime(inst.prefab == 'pumpkin_lantern' and TUNING.PERISH_SUPERSLOW or TUNING.PERISH_PRESERVED) end)

        -- livingtrees (server)
        _iterLivtrees(function(inst)
            if inst._eyeflames then inst._eyeflames:set(true) end
            if inst.components.sanityaura then inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED end
            if inst.components.container then inst.components.container.canbeopened = true end
        end) 

        -- livingroots (server)
        _iterLivroots(function(inst) 
            if inst.prefab == "livingtree_root" then inst.components.inventoryitem:ChangeImageName("livingtree_root_hallowed_nights") end
        end) 
    end

    -- livingtrees (common)
    _iterLivtrees(function(inst) inst.AnimState:Show("eye") end) 

    -- livingroots (common)
    _iterLivroots(function(inst) inst.AnimState:Show("eye") end) 
end


function _stopHalloween()
    if TheWorld.ismastersim then
        -- candy for trinkets (server)
        _iterTrinkets(function(inst) inst.components.tradable.halloweencandyvalue = nil end)

        -- pumpkin perish time (server)
        VEGGIES.pumpkin.perishtime = TUNING.PERISH_MED
        _iterPumpkins(function(inst) inst.components.perishable:SetPerishTime(TUNING.PERISH_MED) end)

        -- livingroots (server)
        _iterLivtrees(function(inst)
            if inst._eyeflames then inst._eyeflames:set(false) end
            if inst.components.sanityaura then inst.components.sanityaura.aura = 0 end
            if inst.components.container then inst.components.container.canbeopened = false end
        end) 

        -- livingroots (server)
        _iterLivroots(function(inst)
            if inst.prefab == "livingtree_root" then inst.components.inventoryitem:ChangeImageName("livingtree_root") end
        end) 
    end

    -- livingtrees (common)
    _iterLivtrees(function(inst) inst.AnimState:Hide("eye") end) 

    -- livingroots (common)
    _iterLivroots(function(inst) inst.AnimState:Hide("eye") end) 
end

--------------------------------------------------------------------------
--[[ Winters Feast ]]
--------------------------------------------------------------------------
-- TODO: components/klaussackspawner postinit - remove timers, remove watchers, call post init
-- TODO: prefabs/deer fn (server) - replicate setupsounds
-- TODO: prefabs/bearger normalfn - set build
-- TODO: prefabs/hermitcrab loadpostpass - learn/forget
-- TODO: prefabs/hermitcrab initfriendstuff - learn/forget?
-- TODO: prefabs/klaus fn (common) - add/clear override
-- TODO: prefabs/klaus fn (server) - add/remove(?) chanceloot... OK? there will be other klauses
-- TODO: prefabs/moose (common) - setbuild
-- TODO: prefabs/mossling (common) - set build
-- TODO: prefabs/playercommon fn - add component, add/remove listen
-- TODO: prefabs/snow - ...whatever, man...

local gingerbreadhunter
local snowballmanager

_trackDeer, _iterDeer = createTracker()
_trackDeerclops, _iterDeerclops = createTracker()
_trackDragonfly, _iterDragonfly = createTracker()

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

--------------------------------------------------------------------------

function _initWintersFeast()
    if TheWorld.ismastersim then
        gingerbreadhunter = TheWorld.components.gingerbreadhunter
        snowballmanager = TheWorld.components.snowballmanager
        
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
    if TheWorld.ismastersim then
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
    end

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

    -- dragonfly (common)
    _iterDragonfly(function(inst) inst.AnimState:SetBuild("dragonfly_yule_build") end)
end

--------------------------------------------------------------------------

function _stopWintersFeast()
    if TheWorld.ismastersim then
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
    end

    -- deer_common (common)
    _iterDeer(function(inst)
        inst.AnimState:ClearOverrideSymbol("deer_hair", "deer_build", "deer_hair_winter")
        inst.AnimState:ClearOverrideSymbol("swap_neck_collar", "deer_build", "swap_neck_collar_winter")
        inst.AnimState:ClearOverrideSymbol("klaus_deer_chain", "deer_build", "klaus_deer_chain_winter")
        inst.AnimState:ClearOverrideSymbol("deer_chest", "deer_build", "deer_chest_winter")
    end)

    -- deerclops common_fn (common)
    _iterDeerclops(function(inst)
        inst.Light:Enable(false)

        inst.build = 'deerclops_build'
        inst.AnimState:SetBuild(inst.build)
    end)

    -- dragonfly (common)
    _iterDragonfly(function(inst) inst.AnimState:SetBuild("dragonfly_build") end)
end

--------------------------------------------------------------------------
--[[ Year of the Gobbler ]]
--------------------------------------------------------------------------
-- TODO: prefabs/perd (server) - component, replicate functions, vars and listeners
-- TODO: prefabs/berrybush (server) - add/kill , change callbacks... but maybe dont (trigger invalid??)
-- TODO: prefabs/perdshrine (server) - replicate functions, callback, watcher... but maybe dont (trigger invalid??)

_trackPerds, _iterPerds = createTracker()

--------------------------------------------------------------------------

function _startYOTG()
    if TheWorld.ismastersim then
        -- Perds (server)
        inst.seekshrine = true
    end

    -- Perds (common)
    _iterPerds(function(inst) inst:AddTag("perd") end)
end

--------------------------------------------------------------------------

function _stopYOTG()
    if TheWorld.ismastersim then
        -- Perds (server)
        inst.seekshrine = nil
    end

    -- Perds (common)
    _iterPerds(function(inst) inst:RemoveTag("perd") end)
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
    if TheWorld.ismastersim then
        -- carrats (server)
       _iterCarrats(function(inst)
            inst:AddComponent("named")
        end)
    end

    -- carrats (common)
    _iterCarrats(function(inst)
        inst.AnimState:AddOverrideBuild("redpouch_yotc")
        if not inst:HasTag("_named") then inst:AddTag("_named") end
    end)

    -- carrat ghostracer
    _iterGhostracer(function(inst) inst.AnimState:AddOverrideBuild("redpouch_yotc") end)
end

--------------------------------------------------------------------------

function _stopYOTC()
    if TheWorld.ismastersim then
        -- carrats (server)
       _iterCarrats(function(inst)
            inst:RemoveComponent("named")
        end)
    end

    -- carrats (common)
    _iterCarrats(function(inst)
        inst.AnimState:ClearOverrideBuild("redpouch_yotc")
        if inst:HasTag("_named") then inst:RemoveTag("_named") end
    end)

    -- carrat ghostracer
    _iterGhostracer(function(inst) inst.AnimState:ClearOverrideBuild("redpouch_yotc") end)
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