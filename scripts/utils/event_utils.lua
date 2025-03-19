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
--[[ Year of the Dragonfly ]]
--------------------------------------------------------------------------

function _startYOTD()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=1})
end

function _stopYOTD()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=0})
end


