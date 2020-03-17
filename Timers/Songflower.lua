local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.Songflower = {}
FADEWT.Songflower.Icon = "Interface\\Icons\\spell_holy_mindvision"
FADEWT.Songflower.TimerLength = 25 * 60
FADEWT.Songflower.Frames = {}
FADEWT.Songflower.LastEventAt = GetServerTime() - 10
FADEWT.Songflower.COMMKEY = "Songbird-3"
FADEWT.Songflower.Locations = {
    ["south1"] = {52.9, 87.83},
    ["south2"] = {45.94, 85.22},
    ["south3"] = {48.26, 75.65},
    ["north4"] = {63.33, 22.61},
    ["north1"] = {63.91, 6.09},
    ["north2"] = {55.8, 10.44},
    ["mid1"]   = {34.35, 52.17},
    ["mid2"]   = {40.15, 56.52},
    ["mid3"]   = {40.14, 44.35},
    ["north3"] = {50.6, 13.9}
}

function FADEWT.Songflower:Tick()
    for key, frame in pairs(FADEWT.Songflower.Frames) do
        frame.title:SetText(FADEWT.Songflower:getFlowerStatus(key, frame))
    end
end

function FADEWT.Songflower.GetTimers()
    local flowers = {
        ["south1"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["south1"],
        ["south2"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["south2"],
        ["south3"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["south3"],
        ["north4"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["north4"],
        ["north1"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["north1"],
        ["north2"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["north2"],
        ["mid1"]   = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["mid1"],
        ["mid2"]   = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["mid2"],
        ["mid3"]   = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["mid3"],
        ["north3"] = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]["north3"]
    }
    return FADEWT.Songflower.COMMKEY, flowers
end

-- Sends report of what flowers are available when
function FADEWT.Songflower.SendReport()
    local _, timers = FADEWT.Songflower.GetTimers()
    for key,timer in pairs(timers) do
        if timer ~= false and timer ~= nil then
            local loc = FADEWT.Songflower.Locations[key]
            print("Songflower at " .. tostring(loc[1]) .. "," .. tostring(loc[2]) .. " available at " .. date('%Y-%m-%d %H:%M:%S', timer))
        end
    end
end

function FADEWT.Songflower:GetMessageData()
    return FADEWT.Songflower.GetTimers()
end

function FADEWT.Songflower.ReceiveTimers(message, distribution, sender)
    if not message then return end
    local didChange = false
    local currTime = GetServerTime()
    for key,timer in pairs(message) do
        --FADEWT.Debug("Receiving songflower timers")
        if timer ~= false and (SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] == nil or SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] == false) and FADEWT.Songflower.Locations[key] ~= nil then
            if timer <= currTime + (FADEWT.Songflower.TimerLength + 3) then
                SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] = timer
                didChange = true
            end
        end
        if timer ~= false and SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] ~= false then
            if (timer > SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key]) and FADEWT.Songflower.Locations[key] ~= nil then
                if timer <= currTime + (FADEWT.Songflower.TimerLength + 3) then
                    SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] = timer
                    didChange = true
                end
            end
        end
    end
end

function FADEWT.Songflower:BroadcastTimers()
    FADEWT:SendMessage()
end


-- Checks if the player is within a given coordinate that matches a songflower one
-- Returns key to the songflower if it exists
function FADEWT.Songflower:ValidatePlayerPosition(x, y)
    for key, coords in pairs(FADEWT.Songflower.Locations) do
        local sX = math.floor(coords[1])
        local sY = math.floor(coords[2])
        -- Measure distance between two coordinates
        local distance = math.sqrt(((x - sX)^2) + ((y - sY)^2))
        if distance < 3 then
            return key
        end
    end
    return false
end

-- Gets status text of a given flower
-- If it's got a cooldown on it, or no status
function FADEWT.Songflower:getFlowerStatus(key, f)
    local flowerTime = SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key]
    local currTime = GetServerTime()
    if flowerTime then
        if flowerTime <= currTime then
            if flowerTime < currTime + (60 * 3) then
                flowerTime = nil
                SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] = false
            end
            f.title:SetTextColor(0, 1, 0, 1)
            return "Ready?"
        end
        if flowerTime > currTime then
            f.title:SetTextColor(1, 0, 0, 1)
            -- Change color to green when 6 minutes or less on the timer
            if (flowerTime - currTime) < 360 then
                f.title:SetTextColor(0, 1, 0, 1)
            end
            local secondsLeft = flowerTime - currTime
            -- Prettify our seconds into minutes and seconds
            mins = string.format("%02.f", math.floor(secondsLeft/60));
            secs = string.format("%02.f", math.floor(secondsLeft - mins * 60));
            return mins .. ":" .. secs
        end
    end
    f.title:SetTextColor(1, 0, 0, 1)
    return ""
end

function FADEWT.Songflower:DebugSongflower()
    local currTime = GetTime()

    -- Check if Sonflower has just been applied
    if 60 == 60 then

        local zId, zT = HBD:GetPlayerZone()
        -- Validate zone just in case
        if not zId == 1448 then return end

        local x,y,instance = HBD:GetPlayerZonePosition()
        x = x * 100
        y = y * 100

        -- Check so that the position is valid
        local key = FADEWT.Songflower:ValidatePlayerPosition(x,y)
        if key then
            -- We know that the songflower was just picked
            FADEWT.Songflower:PickSongflower(key)
        end
    end
end
-- Sends a broadcast if we have any timers to broadcast
function FADEWT.Songflower:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName]) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.Songflower:BroadcastTimers()
    end
end

function FADEWT.Songflower:OnUnitAura(unit)
    if unit == "player" then
        local name, expirationTime, sid, _
        -- Todo: Check if this causes issues
        for i = 1, 40 do
            name, _, _, _, _, expirationTime, _, _, _, sid = UnitAura("player", i, "HELPFUL")
            -- Check for buff Songflower Serenade
            if sid == 15366 then
                local currTime = GetTime()

                -- Check if Sonflower has just been applied
                if (expirationTime - currTime) >= (60 * 60) - 1 then

                    local zId, zT = HBD:GetPlayerZone()
                    -- Validate zone just in case
                    if not zId == 1448 then break end

                    local x,y,instance = HBD:GetPlayerZonePosition()
                    x = x * 100
                    y = y * 100

                    -- Check so that the position is valid
                    local key = FADEWT.Songflower:ValidatePlayerPosition(x,y)

                    if key then
                        -- We know that the songflower was just picked
                        FADEWT.Songflower:PickSongflower(key)
                    end
                end
            end
        end
        
        FADEWT.Songflower:SendBroadcastIfActiveTimer()
    end
end

-- Fires when a songflower is picked
function FADEWT.Songflower:PickSongflower(key)
    local currTime = GetServerTime()
    local cdTime = currTime + (25 * 60)
    SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName][key] = cdTime
    FADEWT.Songflower:BroadcastTimers()
end


function FADEWT.Songflower:Init()
    if FADEWTConfig.SongflowerHidden ~= true then
        FADEWT.Songflower:CreateFrames()
    end
    --Comm:RegisterComm(FADEWT.Songflower.COMMKEY, FADEWT.Songflower.ReceiveTimers)
    FADEWT:RegisterMessageHandler(FADEWT.Songflower.COMMKEY, FADEWT.Songflower.ReceiveTimers)
end


-- Adds a frame to the world map
-- In this case it's a Songflower icon with a possible timer below it
function FADEWT.Songflower:addFrameToWorldMap(key, frame, coords)
    if HBDP then
        FADEWT.Songflower.Frames[key] = frame
        HBDP:AddWorldMapIconMap(FADEWT.Songflower.Frames[key], frame, 1448, coords[1] / 100, coords[2] / 100, showFlag);
    end
end

-- Creates our world map nodes on addon init
function FADEWT.Songflower:CreateFrames()
    for key, coords in pairs(FADEWT.Songflower.Locations) do
        local frame = FADEWT.Songflower:GetFrame()
        FADEWT.Songflower:addFrameToWorldMap(key, frame, coords)
    end
end

-- Setup the frame
function FADEWT.Songflower:GetFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(16)
    f:SetHeight(16)
    f.background = f:CreateTexture(nil, "BACKGROUND")
    f.background:SetAllPoints()
    f.background:SetDrawLayer("BORDER", 1)
    f.background:SetTexture(FADEWT.Songflower.Icon)

    f.title = f:CreateFontString("")
    f.title:SetFontObject("GameFontNormalMed3")
    f.title:SetTextColor(1,0,0,1)
    f.title:SetText("")
    f.title:ClearAllPoints()
    f.title:SetPoint("BOTTOM", f, "BOTTOM", 0, -12)
    f.title:SetTextHeight(12)
    f.title:Show()
    f:Show()
    return f
end

-- Create an empty object if none exist
function FADEWT.Songflower:SetupDB()
    if SongflowerTimers == nil then
        SongflowerTimers = {}
        SongflowerTimers[FADEWT.Songflower.COMMKEY] = {}
        SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName] = {}
    end
    if  SongflowerTimers[FADEWT.Songflower.COMMKEY] == nil then
        SongflowerTimers[FADEWT.Songflower.COMMKEY] = {}
    end
    if SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName] == nil then
        SongflowerTimers[FADEWT.Songflower.COMMKEY][FADEWT.RealmName] = {}
    end
    SongflowerTimers[FADEWT.RealmName] = nil
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.Songflower )