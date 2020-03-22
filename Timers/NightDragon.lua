local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.NightDragon = {}
FADEWT.NightDragon.Icon = "Interface\\Icons\\inv_misc_food_45"
FADEWT.NightDragon.TimerLength = 25 * 60
FADEWT.NightDragon.Frames = {}
FADEWT.NightDragon.LastEventAt = GetServerTime() - 10
FADEWT.NightDragon.COMMKEY = "NightDragon-2"
FADEWT.NightDragon.Locations = {
    ["dragon1"] = {40.72, 78.26},
    ["dragon2"] = {35.11, 58.93},
    ["dragon3"] = {50.58, 30.43},
    ["dragon4"] = {42.46, 13.91}
}

function FADEWT.NightDragon:Tick()
    for key, frame in pairs(FADEWT.NightDragon.Frames) do
        frame.title:SetText(FADEWT.NightDragon:getRootStatus(key, frame))
    end
end

function FADEWT.NightDragon:GetMessageData()
    local timers = {
        ["dragon1"] = NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName]["dragon1"],
        ["dragon2"] = NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName]["dragon2"],
        ["dragon3"] = NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName]["dragon3"],
        ["dragon4"] = NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName]["dragon4"]
    }
    
    return FADEWT.NightDragon.COMMKEY, timers
end

function FADEWT.NightDragon.GetTimers()
    return FADEWT.NightDragon.COMMKEY, NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName]
end


function FADEWT.NightDragon.ReceiveTimers(message, distribution, sender)
    if not message then return end
    local didChange = false
    for key,timer in pairs(message) do
        if timer ~= false and (NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] == nil or NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] == false) then
            NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] = timer
            didChange = true
        end
        if timer ~= false and NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] ~= false then
            if timer > NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] then
                NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] = timer
                didChange = true
            end
        end
    end
end

function FADEWT.NightDragon:BroadcastTimers()
    FADEWT:SendMessage()
end


-- Checks if the player is within a given coordinate that matches a Whipper Root one
-- Returns key to the NightDragon if it exists
function FADEWT.NightDragon:ValidatePlayerPosition(x, y)
    for key, coords in pairs(FADEWT.NightDragon.Locations) do
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

-- Gets status text of a given Root
-- If it's got a cooldown on it, or no status
function FADEWT.NightDragon:getRootStatus(key, f)
    local RootTime = NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key]
    local currTime = GetServerTime()
    if RootTime then
        if RootTime <= currTime then
            if RootTime < currTime + (60 * 3) then
                RootTime = nil
                NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] = false
            end
            f.title:SetTextColor(0, 1, 0, 1)
            return "Ready?"
        end
        if RootTime > currTime then
            f.title:SetTextColor(1, 0, 0, 1)
            -- Change color to green when 6 minutes or less on the timer
            if (RootTime - currTime) < 360 then
                f.title:SetTextColor(0, 1, 0, 1)
            end
            local secondsLeft = RootTime - currTime
            -- Prettify our seconds into minutes and seconds
            mins = string.format("%02.f", math.floor(secondsLeft/60));
            secs = string.format("%02.f", math.floor(secondsLeft - mins * 60));
            return mins .. ":" .. secs
        end
    end
    f.title:SetTextColor(1, 0, 0, 1)
    return ""
end

function FADEWT.NightDragon:DebugNightDragon()
    local currTime = GetTime()

    -- Check if SonRoot has just been applied
    if 60 == 60 then

        local zId, zT = HBD:GetPlayerZone()
        -- Validate zone just in case
        if not zId == 1448 then return end

        local x,y,instance = HBD:GetPlayerZonePosition()
        x = x * 100
        y = y * 100

        -- Check so that the position is valid
        local key = FADEWT.NightDragon:ValidatePlayerPosition(x,y)
        if key then
            -- We know that the NightDragon was just picked
            FADEWT.NightDragon:PickNightDragon(key)
        end
    end
end
-- Sends a broadcast if we have any timers to broadcast
function FADEWT.NightDragon:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName]) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.NightDragon:BroadcastTimers()
    end
end

function FADEWT.NightDragon.OnChatMsgLoot(...)
    local lootstring, _, _, _, player = ...
    local itemID = lootstring:match("|Hitem:(%d+)")
    if itemID == 11952 or itemID == "11952" then
        local zId, zT = HBD:GetPlayerZone()
        -- Validate zone just in case
        if not zId == 1448 then return end
        FADEWT.Debug("Starting to pick Whipper")

        local x,y,instance = HBD:GetPlayerZonePosition()
        x = x * 100
        y = y * 100

        -- Check so that the position is valid
        local key = FADEWT.NightDragon:ValidatePlayerPosition(x,y)

        if key then
            FADEWT.Debug("Position validated")
            -- We know that the NightDragon was just picked
            FADEWT.NightDragon:PickNightDragon(key)
        end

        FADEWT.NightDragon:SendBroadcastIfActiveTimer()
    end
end

-- Fires when a NightDragon is picked
function FADEWT.NightDragon:PickNightDragon(key)
    local currTime = GetServerTime()
    local cdTime = currTime + (25 * 60)
    NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName][key] = cdTime
    FADEWT.NightDragon:BroadcastTimers()
end


function FADEWT.NightDragon:Init()
    if FADEWTConfig.NightDragonHidden ~= true then
        FADEWT.NightDragon:CreateFrames()
    end
    --Comm:RegisterComm(FADEWT.NightDragon.COMMKEY, FADEWT.NightDragon.ReceiveTimers)
    FADEWT:RegisterMessageHandler(FADEWT.NightDragon.COMMKEY, FADEWT.NightDragon.ReceiveTimers)
end


-- Adds a frame to the world map
-- In this case it's a NightDragon icon with a possible timer below it
function FADEWT.NightDragon:addFrameToWorldMap(key, frame, coords)
    if HBDP then
        FADEWT.NightDragon.Frames[key] = frame
        HBDP:AddWorldMapIconMap(FADEWT.NightDragon.Frames[key], frame, 1448, coords[1] / 100, coords[2] / 100, showFlag);
    end
end

-- Creates our world map nodes on addon init
function FADEWT.NightDragon:CreateFrames()
    for key, coords in pairs(FADEWT.NightDragon.Locations) do
        local frame = FADEWT.NightDragon:GetFrame()
        FADEWT.NightDragon:addFrameToWorldMap(key, frame, coords)
    end
end

-- Setup the frame
function FADEWT.NightDragon:GetFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(12)
    f:SetHeight(12)
    f.background = f:CreateTexture(nil, "BACKGROUND")
    f.background:SetAllPoints()
    f.background:SetDrawLayer("BORDER", 1)
    f.background:SetTexture(FADEWT.NightDragon.Icon)

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
function FADEWT.NightDragon:SetupDB()
    if NightDragonTimers == nil then
        NightDragonTimers = {}
        NightDragonTimers[FADEWT.NightDragon.COMMKEY]= {}
        NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName] = {}
    end
    if NightDragonTimers[FADEWT.NightDragon.COMMKEY] == nil then
        NightDragonTimers[FADEWT.NightDragon.COMMKEY] = {}
    end
    if NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName] == nil then
        NightDragonTimers[FADEWT.NightDragon.COMMKEY][FADEWT.RealmName] = {}
    end
    NightDragonTimers[FADEWT.RealmName] = nil
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.NightDragon )