-- Replicates, activates and deactivates all functionalities that would normally be done once at game start,
-- depending on wether the events are active or not, and then left alone throughout the gaming session.

-- The main mod logic is very simple, but here the bulk of the work is done.
-- It's a lot of crap, and there's still a lot to do. Light one up, and let's fucking go.

--------------------------------------------------------------------------

local function createTracker()
    local _tracklist = {}

    local function _removeFn(inst)
        print('[Yearly Seasonal Events] untracking '..tostring(inst))
        _tracklist[inst.GUID] = nil
    end

    local function _trackFn(inst)
        print('[Yearly Seasonal Events] tracking '..tostring(inst))
        _tracklist[inst.GUID] = inst
        inst:ListenForEvent('onremove', _removeFn)
    end

    local function _iterateFn(fn)
        for GUID, inst in pairs(_tracklist) do
            if inst then
                print('[Yearly Seasonal Events] callback on '..tostring(inst))
                fn(inst)
            else
                print('[Yearly Seasonal Events] not found '..GUID)
            end
        end
    end
    return _trackFn, _iterateFn
end

--------------------------------------------------------------------------
--[[ Summer Cawnival ]]
--------------------------------------------------------------------------
-- prefabs/carnival_plaza fn - add component, replicate onactivate, register plaza, add remove callback, add and control spawner
-- prefabs/carnival_crowkit - state flyaway, remove(?)

local carnival_host

--------------------------------------------------------------------------

function _startCarnival()
    if TheWorld.ismastersim then
        if not TheWorld:HasTag('cave') then
            -- carnival host
            if not carnival_host and TheWorld.components.carnivalevent then
                TheWorld.components.carnivalevent:OnPostInit()
                carnival_host = c_find("carnival_host")
            end

            if carnival_host then
                carnival_host.sg:GoToState("glide")
            end
        end
    end
end

--------------------------------------------------------------------------

function _stopCarnival()
    if TheWorld.ismastersim then
        if not TheWorld:HasTag('cave') then
            -- carnival host
            if carnival_host then
                carnival_host.sg:GoToState("flyaway")
                carnival_host:DoTaskInTime(3, carnival_host.Remove)
                carnival_host = nil
            end
        end
    end
end

--------------------------------------------------------------------------
--[[ Hallowed Nights ]]
--------------------------------------------------------------------------
-- prefabs/livingtree fn (server) - change for livingtree_haloween prefab
-- prefabs/livingtree_halloween fn (common) - add net_bool, replicate callback, add/remove listeners, show/hide animstate
-- prefabs/livingtree_halloween fn (server) - toggle bool, add component, toggle aura med/zero, set netvar
-- prefabs/livingtree_root_planted fn (common) - animstate show/hide
-- prefabs/livingtree_root fn (common) - animstate show/hide
-- prefabs/livingtree root fn (server) - change imagename
-- prefabs/playercommon fn - add component, add/remove listen
-- prefabs/pumpkin_lantern - SetPerishTime
-- prefabs/veggies(pumpkin) - SetPerishTime

_trackTrinkets, _iterTrinkets = createTracker()

--------------------------------------------------------------------------

function _startHalloween()
    if TheWorld.ismastersim then
        _iterTrinkets(function(inst) inst.components.tradable.halloweencandyvalue = 5 end)
    end
end


function _stopHalloween()
    if TheWorld.ismastersim then
        _iterTrinkets(function(inst) inst.components.tradable.halloweencandyvalue = nil end)
    end
end

--------------------------------------------------------------------------
--[[ Winters Feast ]]
--------------------------------------------------------------------------
-- components/klaussackspawner postinit - remove timers, remove watchers, call post init
-- prefabs/deerclops normalfn (common) - replicate yulecommonfn, set build and build var
-- prefabs/deerclops normalfn (server) - set yule and laserbeam var, component timer, listener 
-- prefabs/deer fn (server) - replicate setupsounds
-- prefabs/deer common fn - add/clear override
-- prefabs/deer unshackle fn (server) - add/clear override
-- prefabs/deer unshacke (common) - single task...
-- prefabs/bearger normalfn - set build
-- prefabs/dragonfly prefab fn - SetBuild
-- prefabs/dragonfly TransformNormal - call externally as self.TransformNormal 
-- prefabs/dragonfly TransformFire - call externally as self.TransformFire
-- prefabs/hermitcrab loadpostpass - learn/forget
-- prefabs/hermitcrab initfriendstuff - learn/forget?
-- prefabs/klaus fn (common) - add/clear override
-- prefabs/klaus fn (server) - add/remove(?) chanceloot... OK? there will be other klauses
-- prefabs/moose (common) - setbuild
-- prefabs/mossling (common) - set build
-- prefabs/playercommon fn - add component, add/remove listen
-- prefabs/snow - ... whatever, man

local gingerbreadhunter
local snowballmanager

function _initWintersFeast()
    if TheWorld.ismastersim then
        gingerbreadhunter = TheWorld.components.gingerbreadhunter
        snowballmanager = TheWorld.components.snowballmanager
        
        -- gingerbread hunting
        if not TheWorld:HasTag('cave') and not gingerbreadhunter then
            print('[Yearly Seasonal Events] Adding and disabling gingerbreadhunter component.')
            TheWorld:AddComponent("gingerbreadhunter")
            gingerbreadhunter.__OnIsDay = gingerbreadhunter.OnIsDay
            gingerbreadhunter.OnIsDay = function() end
            gingerbreadhunter.disabled = true
        end
    end
end

--------------------------------------------------------------------------

function _startWintersFeast()
    if TheWorld.ismastersim then
        if not TheWorld:HasTag('cave') then
            -- gingerbread hunting
            if gingerbreadhunter.disabled then
                print('[Yearly Seasonal Events] Reenabling gingerbreadhunter component.')
                gingerbreadhunter.OnIsDay = gingerbreadhunter.__OnIsDay
                gingerbreadhunter.__OnIsDay = nil
                gingerbreadhunter.disabled = nil
                -- skip two days to start hunt on day 1
                TheWorld.components.gingerbreadhunter:OnIsDay()
                TheWorld.components.gingerbreadhunter:OnIsDay()
            else
                print('[Yearly Seasonal Events] gingerbreadhunter already enabled.')
            end
        end
    end
end

--------------------------------------------------------------------------

function _stopWintersFeast()
    if TheWorld.ismastersim then
        if not TheWorld:HasTag('cave') then
            -- gingerbread hunting
            if gingerbreadhunter and gingerbreadhunter.disabled == true then
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
            
            -- snowballs
            if snowballmanager and snowballmanager.enabled == true then
                print('[Yearly Seasonal Events] Removing snowball spawning.')
                snowballmanager:SetEnabled(false)
            end
        end
    end
end

--------------------------------------------------------------------------
--[[ Year of the Gobbler ]]
--------------------------------------------------------------------------
-- prefabs/perd (common) - add/remove tag
-- prefabs/perd (server) - component, replicate functions, vars and listeners
-- prefabs/berrybush (server) - add/kill , change callbacks... but maybe dont (trigger invalid??)
-- prefabs/perdshrine (server) - replicate functions, callback, watcher

--------------------------------------------------------------------------
--[[ Year of the Varg ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Year of the Pig King ]]
--------------------------------------------------------------------------
-- prefabs/pigking (common) - toggle add/clear override
-- prefabs/goldnugget - toggle minigame tag


--------------------------------------------------------------------------
--[[ Year of the Carrat ]]
--------------------------------------------------------------------------
-- prefabs/carrat ghostracer - add/remove overridebuild
-- prefabs/carrat fn (common) - add/remove tag, add/remove override build, replicate get_dropaction_string
-- prefabs/carrat fn (server) - replicate train funcs, replicate callbacks, remove tag, add components, add/kill listeners
-- prefabs/beefaloherd fn - replicate carrat spawner and add/remove listen
-- prefabs/rat_gym (server) - add component, replicate callbacks

--------------------------------------------------------------------------
--[[ Year of the Beefalo ]]
--------------------------------------------------------------------------
-- prefabs/merm (common) - toggle add/remove override
-- prefabs/pigman (common) - toggle add/clear override
-- playercommon fn (common) - add/remove netint, replicate and do task... or not (skins?)

--------------------------------------------------------------------------
--[[ Year of the Catcoon ]]
--------------------------------------------------------------------------
-- prefabs/kitcoon - replicate and add/remove callback

--------------------------------------------------------------------------
--[[ Year of the Bunnyman ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Year of the Dragonfly ]]
--------------------------------------------------------------------------

function _startYOTD()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=1})
end

function _stopYOTD()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=0})
end

--------------------------------------------------------------------------
--[[ Year of the Depth Worm ]]
--------------------------------------------------------------------------
-- prefabs/shadowthrall (server) - replicate and set lootsetupfn
-- prefabs/worm (server) - replicate and set loot fn
