local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.Onyxia = {}
FADEWT.Onyxia.Icon = "Interface\\Icons\\Inv_misc_head_dragon_01"

FADEWT.Onyxia.TimerLength = (60 * 60) * 6
FADEWT.Onyxia.Frames = {}
FADEWT.Onyxia.Locations = {
    ["1453"] = {60.50, 75.20},
    ["1454"] = {51.73, 77.69},
}

function FADEWT.Onyxia:Tick()
    for key, frame in pairs(FADEWT.Onyxia.Frames) do
        frame.title:SetText(FADEWT.Onyxia:GetTimerStatus(key, frame))
    end
end
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

function FADEWT.Onyxia:GetTimerStatus(key, f)
    local onyxiaTime = OnyxiaTimers[key]
    local currTime = GetServerTime()
    if onyxiaTime then
        if onyxiaTime <= currTime then
            if onyxiaTime < currTime + (60 * 15) then
                onyxiaTime = nil
                OnyxiaTimers[key] = false
            end
            f.title:SetTextColor(0, 1, 0, 1)
            return "Ready?"
        end
        if onyxiaTime > currTime then
            f.title:SetTextColor(1, 0, 0, 1)
            -- Change color to green when 6 minutes or less on the timer
            if (onyxiaTime - currTime) < 360 then
                f.title:SetTextColor(0, 1, 0, 1)
            end
            
            local secondsLeft = onyxiaTime - currTime
            if secondsLeft <= 0 then
                return "00:00:00";
            else
                hours = string.format("%02.f", math.floor(secondsLeft/3600));
                mins = string.format("%02.f", math.floor(secondsLeft/60 - (hours*60)));
                secs = string.format("%02.f", math.floor(secondsLeft - hours*3600 - mins *60));
                return hours..":"..mins..":"..secs
            end
        end
    end
    f.title:SetTextColor(1, 0, 0, 1)
    return ""
end

function FADEWT.Onyxia:ReceiveTimers(message, distribution, sender)
    local ok, receivedTimers = Serializer:Deserialize(message)
    if not ok or not receivedTimers then return end
    local didChange = false
    for key,timer in pairs(receivedTimers) do
        if timer ~= false and (OnyxiaTimers[key] == nil or OnyxiaTimers[key] == false) then
            OnyxiaTimers[key] = timer
            didChange = true
        end
        if timer ~= false and OnyxiaTimers[key] ~= false then
            if timer > OnyxiaTimers[key] then
                OnyxiaTimers[key] = timer
                didChange = true
            end
        end
    end
    if didChange == true and sender ~= UnitName("player")  then
        FADEWT.Onyxia:BroadcastTimers()
    end
end

function FADEWT.Onyxia:ReceiveOnyxiaBuff(key)
    local currTime = GetServerTime()
    local cdTime = currTime + FADEWT.Onyxia.TimerLength
    OnyxiaTimers[key] = cdTime
    FADEWT.Onyxia:BroadcastTimers()
end

function FADEWT.Onyxia:OnUnitAura(unit)
    if unit == "player" then
        local name, expirationTime, sid, _
        -- Todo: Check if this causes issues
        FADEWT.Onyxia:SendBroadcastIfActiveTimer()
        for i = 1, 40 do
            name, _, _, _, _, expirationTime, _, _, _, sid = UnitAura("player", i, "HELPFUL")
            -- Check for buff Songflower Serenade
            if name == "Rallying Cry of the Dragonslayer" then
                local currTime = GetTime()

                -- Check if Sonflower has just been applied
                if (expirationTime - currTime) >= (60 * 120) - 5 then
                    local zId, zT = HBD:GetPlayerZone()
                    FADEWT.Onyxia:ReceiveOnyxiaBuff(tostring(zId))
                end
            end
        end
    end
end


-- Create an empty object if none exist
function FADEWT.Onyxia:SetupDB()
    if OnyxiaTimers == nil then
        OnyxiaTimers = {}
    end
end
-- Adds a frame to the world map
-- In this case it's a Songflower icon with a possible timer below it
function FADEWT.Onyxia:addFrameToWorldMap(map, frame, coords)
    if HBDP then
        FADEWT.Onyxia.Frames[map] = frame
        HBDP:AddWorldMapIconMap(FADEWT.Onyxia.Frames[map], frame, tonumber(map), coords[1] / 100, coords[2] / 100, showFlag);
    end
end

-- Creates our world map nodes on addon init
function FADEWT.Onyxia:CreateFrames()
    for map, coords in pairs(FADEWT.Onyxia.Locations) do
        local frame = FADEWT.Onyxia:GetFrame()
        FADEWT.Onyxia:addFrameToWorldMap(map, frame, coords)
    end
end


function FADEWT.Onyxia:Init()
    FADEWT.Onyxia:CreateFrames()
    Comm:RegisterComm("FADEWT-ONY", FADEWT.Onyxia.ReceiveTimers)
end

-- Setup the frame
function FADEWT.Onyxia:GetFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(16)
    f:SetHeight(16)
    f.background = f:CreateTexture(nil, "BACKGROUND")
    f.background:SetAllPoints()
    f.background:SetDrawLayer("BORDER", 1)
    f.background:SetTexture(FADEWT.Onyxia.Icon)

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

-- Sends a broadcast if we have any timers to broadcast
function FADEWT.Onyxia:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(OnyxiaTimers) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.Onyxia:BroadcastTimers()
    end
end

function FADEWT.Onyxia:BroadcastTimers()
    local serializedTimers = Serializer:Serialize(OnyxiaTimers)

    Comm:SendCommMessage("FADEWT-ONY", serializedTimers, "YELL");

    if (IsInRaid()) then
        Comm:SendCommMessage("FADEWT-ONY", serializedTimers, "RAID");
    end

    if (GetGuildInfo("player") ~= nil) then
        Comm:SendCommMessage("FADEWT-ONY", serializedTimers, "GUILD");
    end
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.Onyxia )