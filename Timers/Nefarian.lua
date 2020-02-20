local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.Nefarian = {}
FADEWT.Nefarian.Icon = "Interface\\Icons\\Inv_misc_head_dragon_black"
FADEWT.Nefarian.LastEventAt = GetServerTime() - 10

FADEWT.Nefarian.TimerLength = (60 * 60) * 8 -- Nefarian has 8 hour cooldown
FADEWT.Nefarian.Frames = {}
FADEWT.Nefarian.COMMKEY = "FADEWT-NEF3"
FADEWT.Nefarian.Locations = {
    ["1453"] = {64.9, 70},
    ["1454"] = {51.73, 75},
}

function FADEWT.Nefarian:Tick()
    for key, frame in pairs(FADEWT.Nefarian.Frames) do
        frame.title:SetText(FADEWT.Nefarian:GetTimerStatus(key, frame))
    end
end

function FADEWT.Nefarian:GetTimerStatus(key, f)
    local nefarianTime = NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key]
    local currTime = GetServerTime()
    if nefarianTime then
        if nefarianTime <= currTime then
            if nefarianTime < currTime + (60 * 15) then
                nefarianTime = nil
                NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] = false
            end
            f.title:SetTextColor(0, 1, 0, 1)
            return "Ready?"
        end
        if nefarianTime > currTime then
            f.title:SetTextColor(1, 0, 0, 1)
            -- Change color to green when 6 minutes or less on the timer
            if (nefarianTime - currTime) < 360 then
                f.title:SetTextColor(0, 1, 0, 1)
            end
            
            local secondsLeft = nefarianTime - currTime
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

function FADEWT.Nefarian:GetMessageData()
    local timers = {
        ["1453"] = NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName]["1453"],
        ["1454"] = NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName]["1454"],
    }
    return FADEWT.Nefarian.COMMKEY, timers
end

function FADEWT.Nefarian.ReceiveTimers(message, distribution, sender)
    --local ok, receivedTimers = Serializer:Deserialize(message)
    if not message then return end
    local didChange = false
    local currTime = GetServerTime()
    for key,timer in pairs(message) do
        
        if timer ~= false and (NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] == nil or NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] == false) and FADEWT.Nefarian.Locations[key] ~= nil then
            --FADEWT.Debug("RECV ONY TIMER", timer, (currTime + FADEWT.Nefarian.TimerLength + 10) > timer)
            if (currTime + FADEWT.Nefarian.TimerLength + 20) > timer then
                NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] = timer
                didChange = true
            end
        end
        if timer ~= false and NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] ~= false then
            --FADEWT.Debug("RECV ONY TIMER", timer, (currTime + FADEWT.Nefarian.TimerLength + 10) > timer)
            if (timer > NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key]) and FADEWT.Nefarian.Locations[key] ~= nil then
                if (currTime + FADEWT.Nefarian.TimerLength + 20) > timer then
                    NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] = timer
                    didChange = true
                end
            end
        end
    end
end

function FADEWT.Nefarian:ReceiveNefarianBuff(key)
    local currTime = GetServerTime()
    local cdTime = currTime + FADEWT.Nefarian.TimerLength
    NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName][key] = cdTime
    FADEWT.Nefarian:BroadcastTimers()
end

--[[function FADEWT.Nefarian:OnUnitAura(unit)
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
                    FADEWT.Nefarian:ReceiveNefarianBuff(tostring(zId))
                end
            end
        end
        FADEWT.Nefarian:SendBroadcastIfActiveTimer()
    end
end]]

function FADEWT.Nefarian:OnMsgMonsterYell( npc )
    --print("NEFARIAN npc : " .. npc)
    if npc == "High Overlord Saurfang" or npc == "Field Marshal Afrasiabi"then
        local zId, zT = HBD:GetPlayerZone()
        FADEWT.Nefarian:ReceiveNefarianBuff(tostring(zId))
        FADEWT.Nefarian:SendBroadcastIfActiveTimer()
    end
end


-- Create an empty object if none exist
function FADEWT.Nefarian:SetupDB()
    if NefarianTimers == nil then
        NefarianTimers = {}
        NefarianTimers[FADEWT.Nefarian.COMMKEY] = {}
        NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName] = {}
    end
    if NefarianTimers[FADEWT.Nefarian.COMMKEY] == nil then
        NefarianTimers[FADEWT.Nefarian.COMMKEY] = {}
    end
    if NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName] == nil then
        NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName] = {}
    end
    NefarianTimers[FADEWT.RealmName] = nil
end
-- Adds a frame to the world map
-- In this case it's a Songflower icon with a possible timer below it
function FADEWT.Nefarian:addFrameToWorldMap(map, frame, coords)
    if HBDP then
        FADEWT.Nefarian.Frames[map] = frame
        HBDP:AddWorldMapIconMap(FADEWT.Nefarian.Frames[map], frame, tonumber(map), coords[1] / 100, coords[2] / 100, showFlag);
    end
end

-- Creates our world map nodes on addon init
function FADEWT.Nefarian:CreateFrames()
    for map, coords in pairs(FADEWT.Nefarian.Locations) do
        local frame = FADEWT.Nefarian:GetFrame()
        FADEWT.Nefarian:addFrameToWorldMap(map, frame, coords)
    end
end


function FADEWT.Nefarian:Init()
    if FADEWTConfig.NefarianHidden ~= true then
        FADEWT.Nefarian:CreateFrames()
    end
    --Comm:RegisterComm("FADEWT-ONY", FADEWT.Nefarian.ReceiveTimers)
    FADEWT:RegisterMessageHandler(FADEWT.Nefarian.COMMKEY, FADEWT.Nefarian.ReceiveTimers)
end

-- Setup the frame
function FADEWT.Nefarian:GetFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(16)
    f:SetHeight(16)
    f.background = f:CreateTexture(nil, "BACKGROUND")
    f.background:SetAllPoints()
    f.background:SetDrawLayer("BORDER", 1)
    f.background:SetTexture(FADEWT.Nefarian.Icon)

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

function FADEWT.Nefarian.GetTimers()
    return FADEWT.Nefarian.COMMKEY, NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName]
end


-- Sends a broadcast if we have any timers to broadcast
function FADEWT.Nefarian:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(NefarianTimers[FADEWT.Nefarian.COMMKEY][FADEWT.RealmName]) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.Nefarian:BroadcastTimers()
    end
end

function FADEWT.Nefarian:BroadcastTimers()
    FADEWT:SendMessage()
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.Nefarian )