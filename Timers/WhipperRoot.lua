local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.WhipperRoot = {}
FADEWT.WhipperRoot.Icon = "Interface\\Icons\\inv_misc_food_55"
FADEWT.WhipperRoot.TimerLength = 25 * 60
FADEWT.WhipperRoot.Frames = {}
FADEWT.WhipperRoot.LastEventAt = GetServerTime() - 10
FADEWT.WhipperRoot.COMMKEY = "WhipperRoot-1"
FADEWT.WhipperRoot.Locations = {
    ["tuber1"] = {40.14, 85.22},
    ["tuber2"] = {50.58, 18.26},
    ["tuber3"] = {49.42, 12.17},
    ["tuber4"] = {40.72, 19.13},
    ["tuber5"] = {43.04, 46.96},
    ["tuber6"] = {34.06, 60.23}
}

function FADEWT.WhipperRoot:Tick()
    for key, frame in pairs(FADEWT.WhipperRoot.Frames) do
        frame.title:SetText(FADEWT.WhipperRoot:getRootStatus(key, frame))
    end
end

function FADEWT.WhipperRoot:GetMessageData()
    return FADEWT.WhipperRoot.COMMKEY, WhipperRootTimers
end

function FADEWT.WhipperRoot.ReceiveTimers(message, distribution, sender)
    if not message then return end
    local didChange = false
    for key,timer in pairs(message) do
        if timer ~= false and (WhipperRootTimers[key] == nil or WhipperRootTimers[key] == false) then
            WhipperRootTimers[key] = timer
            didChange = true
        end
        if timer ~= false and WhipperRootTimers[key] ~= false then
            if timer > WhipperRootTimers[key] then
                WhipperRootTimers[key] = timer
                didChange = true
            end
        end
    end
    if didChange == true and sender ~= UnitName("player")  then
        FADEWT.WhipperRoot:BroadcastTimers()
    end
end

function FADEWT.WhipperRoot:BroadcastTimers()
    FADEWT:SendMessage()
end


-- Checks if the player is within a given coordinate that matches a Whipper Root one
-- Returns key to the WhipperRoot if it exists
function FADEWT.WhipperRoot:ValidatePlayerPosition(x, y)
    for key, coords in pairs(FADEWT.WhipperRoot.Locations) do
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
function FADEWT.WhipperRoot:getRootStatus(key, f)
    local RootTime = WhipperRootTimers[key]
    local currTime = GetServerTime()
    if RootTime then
        if RootTime <= currTime then
            if RootTime < currTime + (60 * 3) then
                RootTime = nil
                WhipperRootTimers[key] = false
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

function FADEWT.WhipperRoot:DebugWhipperRoot()
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
        local key = FADEWT.WhipperRoot:ValidatePlayerPosition(x,y)
        if key then
            -- We know that the WhipperRoot was just picked
            FADEWT.WhipperRoot:PickWhipperRoot(key)
        end
    end
end
-- Sends a broadcast if we have any timers to broadcast
function FADEWT.WhipperRoot:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(WhipperRootTimers) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.WhipperRoot:BroadcastTimers()
    end
end

function FADEWT.WhipperRoot.OnChatMsgLoot(...)
    local lootstring, _, _, _, player = ...
    local itemLink = string.match(lootstring,"|%x+|Hitem:.-|h.-|h|r")
    local itemString = string.match(itemLink, "item[%-?%d:]+")
    local itemName = GetItemInfo(itemString)
    if itemName == "Whipper Root Tuber" then
        local zId, zT = HBD:GetPlayerZone()
        -- Validate zone just in case
        if not zId == 1448 then return end

        local x,y,instance = HBD:GetPlayerZonePosition()
        x = x * 100
        y = y * 100

        -- Check so that the position is valid
        local key = FADEWT.WhipperRoot:ValidatePlayerPosition(x,y)

        if key then
            -- We know that the WhipperRoot was just picked
            FADEWT.WhipperRoot:PickWhipperRoot(key)
        end

        FADEWT.WhipperRoot:SendBroadcastIfActiveTimer()
    end
end

-- Fires when a WhipperRoot is picked
function FADEWT.WhipperRoot:PickWhipperRoot(key)
    local currTime = GetServerTime()
    local cdTime = currTime + (25 * 60)
    WhipperRootTimers[key] = cdTime
    FADEWT.WhipperRoot:BroadcastTimers()
end


function FADEWT.WhipperRoot:Init()
    if FADEWTConfig.WhipperRootHidden ~= true then
        FADEWT.WhipperRoot:CreateFrames()
    end
    --Comm:RegisterComm(FADEWT.WhipperRoot.COMMKEY, FADEWT.WhipperRoot.ReceiveTimers)
    FADEWT:RegisterMessageHandler(FADEWT.WhipperRoot.COMMKEY, FADEWT.WhipperRoot.ReceiveTimers)
end


-- Adds a frame to the world map
-- In this case it's a WhipperRoot icon with a possible timer below it
function FADEWT.WhipperRoot:addFrameToWorldMap(key, frame, coords)
    if HBDP then
        FADEWT.WhipperRoot.Frames[key] = frame
        HBDP:AddWorldMapIconMap(FADEWT.WhipperRoot.Frames[key], frame, 1448, coords[1] / 100, coords[2] / 100, showFlag);
    end
end

-- Creates our world map nodes on addon init
function FADEWT.WhipperRoot:CreateFrames()
    for key, coords in pairs(FADEWT.WhipperRoot.Locations) do
        local frame = FADEWT.WhipperRoot:GetFrame()
        FADEWT.WhipperRoot:addFrameToWorldMap(key, frame, coords)
    end
end

-- Setup the frame
function FADEWT.WhipperRoot:GetFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(12)
    f:SetHeight(12)
    f.background = f:CreateTexture(nil, "BACKGROUND")
    f.background:SetAllPoints()
    f.background:SetDrawLayer("BORDER", 1)
    f.background:SetTexture(FADEWT.WhipperRoot.Icon)

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
function FADEWT.WhipperRoot:SetupDB()
    if WhipperRootTimers == nil then
        WhipperRootTimers = {}
    end
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.WhipperRoot )