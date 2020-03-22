local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local Comm = LibStub("AceComm-3.0")
local Serializer = LibStub("AceSerializer-3.0")

FADEWT.WCB = {}
FADEWT.WCB.Icon = "Interface\\Icons\\spell_arcane_teleportorgrimmar"
FADEWT.WCB.LastEventAt = GetServerTime() - 10
FADEWT.WCB.TimerLength = (60 * 60) * 3
FADEWT.WCB.Frames = {}
FADEWT.WCB.COMMKEY = "FADEWT-WCB3"
FADEWT.WCB.Locations = {
    ["1454"] = {45, 30},
}

function FADEWT.WCB:Tick()
    for key, frame in pairs(FADEWT.WCB.Frames) do
        frame.title:SetText(FADEWT.WCB:GetTimerStatus(key, frame))
    end
end

function FADEWT.WCB:GetMessageData()
    local timer = {}
    timer["1454"] = WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]["1454"]
    return FADEWT.WCB.COMMKEY, timer
end

function FADEWT.WCB.SendReport()
    local timer = WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]["1454"]
    if timer == nil or timer == false then
        print("No WCB timer available")
        return nil
    end
    print("WCB ready at - ", date('%Y-%m-%d %H:%M:%S', WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]["1454"]) )

end

function FADEWT.WCB:GetTimerStatus(key, f)
    local WCBTime = WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key]
    local currTime = GetServerTime()
    if WCBTime then
        if WCBTime <= currTime then
            if WCBTime < currTime + (60 * 15) then
                WCBTime = nil
                WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] = false
            end
            f.title:SetTextColor(0, 1, 0, 1)
            return "Ready?"
        end
        if WCBTime > currTime then
            f.title:SetTextColor(1, 0, 0, 1)
            -- Change color to green when 6 minutes or less on the timer
            if (WCBTime - currTime) < 360 then
                f.title:SetTextColor(0, 1, 0, 1)
            end
            
            local secondsLeft = WCBTime - currTime
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

function FADEWT.WCB.ReceiveTimers(message, distribution, sender)
    --local ok, receivedTimers = Serializer:Deserialize(message);
    if not message then return end
    local didChange = false
    if type(message) ~= "table" then
        return
    end
    local currTime = GetServerTime()
    for key,timer in pairs(message) do
        if timer ~= false and (WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] == nil or WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] == false) then
            --FADEWT.Debug("RECV WCB TIMER", timer, (currTime + FADEWT.WCB.TimerLength + 10) > timer)
            if ((currTime + FADEWT.WCB.TimerLength + 10) > timer) and FADEWT.WCB.Locations[key] ~= nil then
                WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] = timer
                FADEWT.Debug("Got new WCB timer from", sender, "through", distribution, " - timer: ", timer)
                didChange = true
            end
        end
        if timer ~= false and WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] ~= false then
            --FADEWT.Debug("RECV WCB TIMER", timer, (currTime + FADEWT.WCB.TimerLength + 10) > timer)
            if timer > WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] then
                if ((currTime + FADEWT.WCB.TimerLength + 10) > timer) and FADEWT.WCB.Locations[key] ~= nil then
                    WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName][key] = timer
                    FADEWT.Debug("Got new WCB timer from", sender, "through", distribution, " - timer: ", timer)
                    didChange = true
                end
            end
        end
    end
end

function FADEWT.WCB:ReceiveWCBBuff()
    local currTime = GetServerTime()
    local cdTime = currTime + FADEWT.WCB.TimerLength
    WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]["1454"] = cdTime
    FADEWT.WCB:BroadcastTimers()
end

-- Sends a broadcast if we have any timers to broadcast
function FADEWT.WCB:SendBroadcastIfActiveTimer()
    local shouldBroadcast = false
    for key,timer in pairs(WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]) do
        if timer then
            shouldBroadcast = true
        end
    end

    if shouldBroadcast then
        FADEWT.WCB:BroadcastTimers()
    end
end

function FADEWT.WCB:OnUnitAura(unit)
    if unit == "player" then
        local name, expirationTime, sid, _
        -- Todo: Check if this causes issues
        for i = 1, 40 do
            name, _, _, _, _, expirationTime, _, _, _, sid = UnitAura("player", i, "HELPFUL")
            -- Check for buff Songflower Serenade
            if sid == 16609 then
                local currTime = GetTime()

                -- Check if Sonflower has just been applied
                if ((expirationTime - currTime) >= (60 * 60) - 1) and (currTime > (FADEWT.InitTime + 2)) then
                    
                    FADEWT.WCB:ReceiveWCBBuff()
                    FADEWT.WCB:SendBroadcastIfActiveTimer()
                end
            end
        end
        FADEWT.WCB:SendBroadcastIfActiveTimer()
    end
end


-- Create an empty object if none exist
function FADEWT.WCB:SetupDB()
    if WCBTimers == nil then
        WCBTimers = {}
        WCBTimers[FADEWT.WCB.COMMKEY] = {}
        WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName] = {}
    end
    if WCBTimers[FADEWT.WCB.COMMKEY] == nil then
        WCBTimers[FADEWT.WCB.COMMKEY] = {}
    end
    if WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName] == nil then
        WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName] = {}
    end
    WCBTimers[FADEWT.RealmName] = nil
end
-- Adds a frame to the world map
-- In this case it's a Songflower icon with a possible timer below it
function FADEWT.WCB:addFrameToWorldMap(map, frame, coords)
    if HBDP then
        FADEWT.WCB.Frames[map] = frame
        HBDP:AddWorldMapIconMap(FADEWT.WCB.Frames[map], frame, tonumber(map), coords[1] / 100, coords[2] / 100, showFlag);
    end
end

-- Creates our world map nodes on addon init
function FADEWT.WCB:CreateFrames()
    for map, coords in pairs(FADEWT.WCB.Locations) do
        local frame = FADEWT.WCB:GetFrame()
        FADEWT.WCB:addFrameToWorldMap(map, frame, coords)
    end
end

-- Clears all timers
-- Used on new version to clear all old timers
function FADEWT.WCB:ClearTimers()
    WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]["1454"] = 0
end

function FADEWT.WCB:Init()
    if FADEWTConfig.WCBHidden ~= true then
        FADEWT.WCB:CreateFrames()
    end

    -- Clears timers when updating to a new version
    -- This is to prevent issues with cross contamination
    -- Versions without updated COMMKEY should still propagate fairly well, but it might prevent some issues
    if FADEWT.VERSION > FADEWTConfig.Version then
        FADEWT.WCB:ClearTimers()
    end

    FADEWT:RegisterMessageHandler(FADEWT.WCB.COMMKEY, FADEWT.WCB.ReceiveTimers)
end

-- Setup the frame
function FADEWT.WCB:GetFrame()
    local f = CreateFrame("Frame", nil, UIParent)
    f:SetFrameStrata("HIGH")
    f:SetWidth(16)
    f:SetHeight(16)
    f.background = f:CreateTexture(nil, "BACKGROUND")
    f.background:SetAllPoints()
    f.background:SetDrawLayer("BORDER", 1)
    f.background:SetTexture(FADEWT.WCB.Icon)

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

function FADEWT.WCB.GetTimers()
    return FADEWT.WCB.COMMKEY, WCBTimers[FADEWT.WCB.COMMKEY][FADEWT.RealmName]
end


function FADEWT.WCB:BroadcastTimers()
    FADEWT:SendMessage()
end

-- Register our World Timer
table.insert( FADEWT.WorldTimers, FADEWT.WCB )