local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.Onyxia = {}
FADEWT.Onyxia.Icon = "Interface\\Icons\\Inv_misc_head_dragon_01"
FADEWT.Onyxia.LastEventAt = GetServerTime() - 10

FADEWT.Onyxia.TimerLength = (60 * 60) * 6
FADEWT.Onyxia.Frames = {}
FADEWT.Onyxia.COMMKEY = "FADEWT-ONY3"
FADEWT.Onyxia.Locations = {
    ["1453"] = {60.50, 75.20},
    ["1454"] = {51.73, 77.69},
}

function FADEWT.Onyxia:Tick()
    for key, frame in pairs(FADEWT.Onyxia.Frames) do
        frame.title:SetText(FADEWT.Onyxia:GetTimerStatus(key, frame))
    end
end

function FADEWT.Onyxia:GetTimerStatus(key, f)
    local onyxiaTime = OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key]
    local currTime = GetServerTime()
    if onyxiaTime then
        if onyxiaTime <= currTime then
            if onyxiaTime < currTime + (60 * 15) then
                onyxiaTime = nil
                OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] = false
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

function FADEWT.Onyxia:GetMessageData()
    local timers = {
        ["1453"] = OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName]["1453"],
        ["1454"] = OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName]["1454"],
    }
    return FADEWT.Onyxia.COMMKEY, timers
end

function FADEWT.Onyxia.ReceiveTimers(message, distribution, sender)
    --local ok, receivedTimers = Serializer:Deserialize(message)
    if not message then return end
    local didChange = false
    local currTime = GetServerTime()
    for key,timer in pairs(message) do
        
        if timer ~= false and (OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] == nil or OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] == false) and FADEWT.Onyxia.Locations[key] ~= nil then
            --FADEWT.Debug("RECV ONY TIMER", timer, (currTime + FADEWT.Onyxia.TimerLength + 10) > timer)
            if (currTime + FADEWT.Onyxia.TimerLength + 20) > timer then
                OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] = timer
                didChange = true
            end
        end
        if timer ~= false and OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] ~= false then
            --FADEWT.Debug("RECV ONY TIMER", timer, (currTime + FADEWT.Onyxia.TimerLength + 10) > timer)
            if (timer > OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key]) and FADEWT.Onyxia.Locations[key] ~= nil then
                if (currTime + FADEWT.Onyxia.TimerLength + 20) > timer then
                    OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] = timer
                    didChange = true
                end
            end
        end
    end
end

function FADEWT.Onyxia:ReceiveOnyxiaBuff(key)
    local currTime = GetServerTime()
    local cdTime = currTime + FADEWT.Onyxia.TimerLength
    OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName][key] = cdTime
    FADEWT.Onyxia:BroadcastTimers()
end

function FADEWT.Onyxia:OnUnitAura(unit)
    if unit == "player" then
        local name, expirationTime, sid, _
        -- Todo: Check if this causes issues
        for i = 1, 40 do
            name, _, _, _, _, expirationTime, _, _, _, sid = UnitAura("player", i, "HELPFUL")
            -- Check for buff Songflower Serenade
            if sid == 22888 then
                local currTime = GetTime()

                -- Check if Sonflower has just been applied
                if ((expirationTime - currTime) >= (60 * 120) - 1) and (currTime > (FADEWT.InitTime + 2)) then
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
        OnyxiaTimers[FADEWT.Onyxia.COMMKEY] = {}
        OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName] = {}
    end
    if OnyxiaTimers[FADEWT.Onyxia.COMMKEY] == nil then
        OnyxiaTimers[FADEWT.Onyxia.COMMKEY] = {}
    end
    if OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName] == nil then
        OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName] = {}
    end
    OnyxiaTimers[FADEWT.RealmName] = nil
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
    if FADEWTConfig.OnyxiaHidden ~= true then
        FADEWT.Onyxia:CreateFrames()
    end
    --Comm:RegisterComm("FADEWT-ONY", FADEWT.Onyxia.ReceiveTimers)
    FADEWT:RegisterMessageHandler(FADEWT.Onyxia.COMMKEY, FADEWT.Onyxia.ReceiveTimers)
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

function FADEWT.Onyxia.GetTimers()
    return FADEWT.Onyxia.COMMKEY, OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName]
end


-- Sends a broadcast if we have any timers to broadcast
function FADEWT.Onyxia:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(OnyxiaTimers[FADEWT.Onyxia.COMMKEY][FADEWT.RealmName]) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.Onyxia:BroadcastTimers()
    end
end

function FADEWT.Onyxia:BroadcastTimers()
    FADEWT:SendMessage()
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.Onyxia )