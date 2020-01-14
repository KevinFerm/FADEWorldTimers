local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local AceTimer = LibStub("AceTimer-3.0")
local Serializer = LibStub("AceSerializer-3.0")
local Comm = LibStub("AceComm-3.0")


------ INITIALIZE ADDON CORE
-----------------------

-- All active timer objects
-- @INTERFACE
-- Locations = {String: {x, y}}
-- TimerLength = Integer (Seconds)
-- function GetFrame - returns frame with title child
-- function Tick - Runs every tick, handles timers on map and their visuals
FADEWT.WorldTimers = {}

FADEWT.MessageCallbacks = {}
FADEWT.COMMKEY = "FADEWT-1"
FADEWT.LastEventAt = GetServerTime() - 10
FADEWT.RealmName = GetRealmName()
-- Initializes our addon
function FADEWT:Init()
    -- Create an empty DB if need be
    FADEWT:SetupDB()

    --Songbird:createNodes()
    local Frame = CreateFrame("Frame", nil, UIParent)

    -- Update the active songflower timers every second
    AceTimer:ScheduleRepeatingTimer(FADEWT.Tick, 1)

    -- Register event on UNIT_AURA so we can check if player got Songflower
    Frame:RegisterEvent("UNIT_AURA")
    Frame:RegisterEvent("CHAT_MSG_LOOT")
    Frame:SetScript("OnEvent", FADEWT.HandleEvent)
    Comm:RegisterComm(FADEWT.COMMKEY, FADEWT.HandleMessage)
    --Comm:RegisterComm("FADEWorldTimers", FADEWT.RecvTimers)

    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.Init ~= nil then
            Timer:Init()
        end
    end
end

-- Fires on every event
-- Todo: Add every needed event here
function FADEWT:HandleEvent(event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        FADEWT:OnUnitAura(self, unit)
    end

    if event == "CHAT_MSG_LOOT" then
        FADEWT:OnChatMsgLoot(self, ...)
    end
end

function FADEWT:OnChatMsgLoot(self, ...)
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.OnChatMsgLoot ~= nil then
            Timer.OnChatMsgLoot(...)
        end
    end
end

-- Runs our init function when ready
function FADEWT:Initialize()
    local f = CreateFrame("FRAME")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("onEvent", function(self, event, addon)
        if event == "ADDON_LOADED" and addon == AddonName then
            FADEWT:Init()
        end
    end)
end

-- This fires every second
-- Is meant to update the timers
-- No need to do it more often, would only cause lag issues
function FADEWT:Tick()
    for _, Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.Tick ~= nil then
            Timer:Tick()
        end
    end
end

-- Fires the OnUnitAura on every WorldTimer that has the function when UNIT_AURA event is fired
function FADEWT:OnUnitAura(self, unit)
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.OnUnitAura ~= nil then
            Timer:OnUnitAura(unit)
        end
    end
end

-- Function for timers to use to register their message handler
function FADEWT:RegisterMessageHandler(key, fn)
    FADEWT.MessageCallbacks[key] = fn
end

-- Handle COMM Messages, send it to the correct message handler, handler needs to be registered to be sent
function FADEWT:HandleMessage(message, distribution, sender)
    local ok, decodedMessage = Serializer:Deserialize(message);
    if not ok or not decodedMessage then return false end
    for key,timers in pairs(decodedMessage) do
        if FADEWT.MessageCallbacks[key] ~= nil then
            FADEWT.MessageCallbacks[key](timers, distribution, sender)
        end
    end
end

-- Sends data from each timer in an aggregated manner, not more than once every 10 seconds
-- Avoids spamming the chat and getting errors because of it
-- Timer needs function GetMessageData before the object is sent
function FADEWT:SendMessage()
    if (GetServerTime() - FADEWT.LastEventAt) <= 10 then return end
    FADEWT.LastEventAt = GetServerTime()
    local messageData = {}
    -- Loop through every timer and get the data they want to send
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.GetMessageData ~= nil then
            local key, data = Timer:GetMessageData()
            messageData[key] = data
        end
    end

    local serializedMessageData = Serializer:Serialize(messageData)
    Comm:SendCommMessage(FADEWT.COMMKEY , serializedMessageData, "YELL");
    if (IsInRaid() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        Comm:SendCommMessage(FADEWT.COMMKEY , serializedMessageData, "RAID");
    end

    if (GetGuildInfo("player") ~= nil) then
        Comm:SendCommMessage(FADEWT.COMMKEY , serializedMessageData, "GUILD");
    end
end

-- Sets up SavedVariabled for all registered timers
-- Also sets up our config object
function FADEWT:SetupDB()

    if FADEWTConfig == nil then
        FADEWTConfig = {}
        FADEWTConfig.OnyxiaHidden = false
        FADEWTConfig.WCBHidden = false
        FADEWTConfig.SongflowerHidden = false
    end

    for _, Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.SetupDB ~= nil then
            Timer:SetupDB()
        end
    end
end

-- Run our initialize script
FADEWT:Initialize()

-- Set our addon object as global
_G["FADEWT"] = FADEWT
------ END INITIALIZE ADDON CORE
---------------------------

