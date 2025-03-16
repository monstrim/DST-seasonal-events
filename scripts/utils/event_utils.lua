-- Replicates, activates and deactivates all functionalities that would normally be done once at game start,
-- depending on wether the events are active or not, and then left alone throughout the gaming session.

-- The main mod logic is very simple, but here the bulk of the work is done.
-- It's a lot of crap, and there's still a lot to do. Light one up, and let's fucking go.

--------------------------------------------------------------------------

local carnival_host

--------------------------------------------------------------------------

local function _startCrow()
    if not carnival_host and TheWorld.components.carnivalevent then
        TheWorld.components.carnivalevent:OnPostInit()
        carnival_host = c_find("carnival_host")
    end

    if carnival_host then
        carnival_host.sg:GoToState("glide")
    end
end


local function _stopCrow()
    if carnival_host then
        carnival_host.sg:GoToState("flyaway")
        carnival_host:DoTaskInTime(3, carnival_host.Remove)
        carnival_host = nil
    end
end

--------------------------------------------------------------------------

local function _startGingerbread()
    if TheWorld:HasTag('cave') then return end
    local cmp = TheWorld.components.gingerbreadhunter

    if not cmp then
        print('[Yearly Seasonal Effects] Adding gingerbreadhunter component.')
        
        TheWorld:AddComponent("gingerbreadhunter")
        TheWorld.components.gingerbreadhunter:OnIsDay()
    elseif cmp.disabled then
        print('[Yearly Seasonal Effects] Reenabling gingerbreadhunter component.')
        
        cmp.OnIsDay = cmp.__OnIsDay
        cmp.__OnIsDay = nil
        cmp.disabled = nil
        TheWorld.components.gingerbreadhunter:OnIsDay()
    end
end


local function _stopGingerbread()
    if TheWorld:HasTag('cave') then return end
    local cmp = TheWorld.components.gingerbreadhunter

    if cmp then
        print('[Yearly Seasonal Effects] Disabling gingerbreadhunter component.')

        cmp.__OnIsDay = cmp.OnIsDay
        cmp.OnIsDay = function() end
        if cmp.newhunttask then
            cmp.newhunttask:Cancel()
            cmp.newhunttask = nil
        end
        cmp.disabled = true
    end
end

local function _stopSnowballs()
    local cmp 
    
    cmp = TheWorld.components.snowballmanager
    if cmp and cmp.enabled == true then
        print('[Yearly Seasonal Effects] Removing snowball spawnining.')
        cmp:SetEnabled(false)
    end
end

--------------------------------------------------------------------------

local function _startDragonflyPrize()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=1})
end


local function _stopDragonflyPrize()
    TheWorld.components.yotd_raceprizemanager:LoadPostPass(nil, {prize=0})
end


