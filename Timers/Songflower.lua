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
FADEWT.Songflower.COMMKEY = "Songbird-1"
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

function FADEWT.Songflower:ReceiveTimers(message, distribution, sender)
    local ok, receivedTimers = Serializer:Deserialize(message);
    
    if not ok or not receivedTimers then return end
    local didChange = false
    for key,timer in pairs(receivedTimers) do
        if timer ~= false and (SongflowerTimers[key] == nil or SongflowerTimers[key] == false) then
            SongflowerTimers[key] = timer
            didChange = true
        end
        if timer ~= false and SongflowerTimers[key] ~= false then
            if timer > SongflowerTimers[key] then
                SongflowerTimers[key] = timer
                didChange = true
            end
        end
    end
    if didChange == true and sender ~= UnitName("player")  then
        FADEWT.Songflower:BroadcastTimers()
    end
end

function FADEWT.Songflower:BroadcastTimers()
    if (GetServerTime() - FADEWT.Songflower.LastEventAt) <= 10 then return end
    local serializedTimers = Serializer:Serialize(SongflowerTimers)

    Comm:SendCommMessage(FADEWT.Songflower.COMMKEY , serializedTimers, "YELL");

    if (IsInRaid()) then
        Comm:SendCommMessage(FADEWT.Songflower.COMMKEY , serializedTimers, "RAID");
    end

    if (GetGuildInfo("player") ~= nil) then
        Comm:SendCommMessage(FADEWT.Songflower.COMMKEY , serializedTimers, "GUILD");
    end
    FADEWT.Songflower.LastEventAt = GetServerTime()
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
    local flowerTime = SongflowerTimers[key]
    local currTime = GetServerTime()
    if flowerTime then
        if flowerTime <= currTime then
            if flowerTime < currTime + (60 * 3) then
                flowerTime = nil
                SongflowerTimers[key] = false
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
    for key,timer in pairs(SongflowerTimers) do
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
            if name == "Songflower Serenade" then
                local currTime = GetTime()

                -- Check if Sonflower has just been applied
                if (expirationTime - currTime)/60 >= 60 then

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
    SongflowerTimers[key] = cdTime
    FADEWT.Songflower:BroadcastTimers()
end


function FADEWT.Songflower:Init()
    FADEWT.Songflower:CreateFrames()
    Comm:RegisterComm(FADEWT.Songflower.COMMKEY, FADEWT.Songflower.ReceiveTimers)
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

    f.title = f:CreateFontString("TESTAR")
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
    end
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.Songflower )