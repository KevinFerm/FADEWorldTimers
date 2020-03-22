local AddonName, FADEWT = ...
local HBDP = LibStub("HereBeDragons-Pins-2.0")
local HBD = LibStub("HereBeDragons-2.0")
local AceTimer = LibStub("AceTimer-3.0")
local Serializer = LibStub("AceSerializer-3.0")
local Comm = LibStub("AceComm-3.0")


------ INITIALIZE ADDON CORE
-----------------------

FADEWT.WorldTimers = {}

FADEWT.MessageCallbacks = {}
FADEWT.COMMKEY = "FADEWT-5" -- CHANGE BACK TO 4
FADEWT.LastEventAt = GetServerTime() - 60
FADEWT.LastYellAt = GetServerTime() - 380
FADEWT.InitTime = GetTime()
FADEWT.RealmName = GetRealmName()
FADEWT.Faction, _ = UnitFactionGroup("player")
FADEWT.VERSION = 129
FADEWT.VERSIONCHECK = 0

-- Initializes our addon
function FADEWT:Init()
    -- Create an empty DB if need be
    FADEWT:SetupDB()

    local Frame = CreateFrame("Frame", nil, UIParent)

    -- Update the active timers every second
    AceTimer:ScheduleRepeatingTimer(FADEWT.Tick, 1)

    -- Every 300 seconds try and send message
    -- Should keep timers fresh
    AceTimer:ScheduleRepeatingTimer(FADEWT.SendMessage, 300)

    -- Register event on UNIT_AURA so we can check if player got timer
    Frame:RegisterEvent("UNIT_AURA")
    Frame:RegisterEvent("CHAT_MSG_LOOT")
    Frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    Frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    Frame:SetScript("OnEvent", FADEWT.HandleEvent)
    Comm:RegisterComm(FADEWT.COMMKEY, FADEWT.HandleMessage)

    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.Init ~= nil then
            Timer:Init()
        end
    end
    
    -- Save current version so we can use it to clear timers from old versions when you update
    FADEWTConfig.Version = FADEWT.VERSION
end

SLASH_FADEWTCMD1 = '/fade';
function SlashCmdList.FADEWTCMD(cmd, editBox)
    if cmd == "print" then
        FADEWT.SendReport()
    else
        print("Welcome to FADE World Timers")
        print("Currently we have timers for:")
        print("Onyxia, Nefarian, Songflower, WCB, Whipper Root Tubers")
        print("----------")
        print("Available Commands:")
        print("print - Prints a list of all active timers and the time left")
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

    if event == "CHAT_MSG_MONSTER_YELL" then
        FADEWT:OnChatMsgMonsterYell(self, ...)
    end

    -- Broadcast message when entering world
    if event == "PLAYER_ENTERING_WORLD" then
        FADEWT:SendMessage()
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        FADEWT:OnUnfilteredCombatLogEvent(self, ...)
    end
end

function FADEWT:OnChatMsgMonsterYell(self, ...)
    local msg, npc = ...
    for _, Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.OnMsgMonsterYell ~= nil then
            Timer:OnMsgMonsterYell(npc)
        end
    end
end

-- Called when loot is received
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

-- Can check when certain combat log events happen
function FADEWT:OnUnfilteredCombatLogEvent(event)
    for _, Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.OnUnfilteredCombatLogEvent ~= nil then
            Timer.OnUnfilteredCombatLogEvent(event, CombatLogGetCurrentEventInfo())
        end
    end
end

-- Function to print a report of all timers currectly active
function FADEWT.SendReport()
    for _, Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.SendReport ~= nil then
            Timer.SendReport()
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
    if sender == UnitName("player") then return false end

    -- Validate if sender is from the same realm as us. Don't continue if not.
    local charName, realm = strsplit("-", sender, 2)
    if realm ~= nil then
        FADEWT.Debug("Message from: ", charName, realm)
        return false
    end

    if decodedMessage["version"] ~= nil then
        local version = decodedMessage["version"]
        if (version > FADEWT.VERSION) and (GetServerTime() > (FADEWT.VERSIONCHECK + 12000)) then
            print("|cFFD13300[FADE World Timers] Your version is out of date - Please download the newest version on Curseforge or through the Twitch Client")
            print("|cFFD13300Using an older version, you will not be able to share your timers with newer versions of the addon.")
            FADEWT.VERSIONCHECK = GetServerTime()
        end

        -- Don't receive updated timers from people with older versions of the addon.
        if (version < FADEWT.VERSION) then
            FADEWT.Debug("Stopped a message from ", sender, " with version: ", version)
            return false
        end
    end

    for key,timers in pairs(decodedMessage) do
        if FADEWT.MessageCallbacks[key] ~= nil then
            FADEWT.MessageCallbacks[key](timers, distribution, sender)
        end
    end
end

function FADEWT:ConvertTimestampToHumanReadable()
    return nil
end

-- Debug message
function FADEWT.Debug(...)
    if FADEWTConfig.Debug == true then
        print("FADEWT", ...)
    end
end

-- Sends data from each timer in an aggregated manner, not more than once every 10 seconds
-- Avoids spamming the chat and getting errors because of it
-- Timer needs function GetMessageData before the object is sent
function FADEWT:SendMessage(force)
    if ((GetServerTime() - FADEWT.LastEventAt) <= 60) and (force ~= true) then return end
    FADEWT.LastEventAt = GetServerTime()
    local messageData = {}

    messageData["version"] = FADEWT.VERSION

    -- Loop through every timer and get the data they want to send
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.GetMessageData ~= nil then
            local key, data = Timer:GetMessageData()
            messageData[key] = data
        end
    end

    local serializedMessageData = Serializer:Serialize(messageData)

    FADEWT.Debug("Broadcasting timers")
    -- TODO: Enable when I'm sure what causes the bugs
    if FADEWTConfig.YellDisabled ~= true and (GetServerTime() - FADEWT.LastYellAt) >= 380 then
        Comm:SendCommMessage(FADEWT.COMMKEY , serializedMessageData, "YELL", nil, "BULK");
        FADEWT.LastYellAt = GetServerTime()
    end

    if (IsInRaid() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        -- Comm:SendCommMessage(FADEWT.COMMKEY , serializedMessageData, "RAID");
    end

    if (GetGuildInfo("player") ~= nil) then
        Comm:SendCommMessage(FADEWT.COMMKEY , serializedMessageData, "GUILD", nil, "BULK");
    end
end

-- Returns active timers for a given timer
function FADEWT:GetTimers()
    local timers = {}
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.GetTimers ~= nil then
            local key, cds = Timer.GetTimers()
            timers[key] = cds
        end
    end
    --print(dump(timers))
    return timers
end

-- Sets up SavedVariabled for all registered timers
-- Also sets up our config object
function FADEWT:SetupDB()

    if FADEWTConfig == nil then
        FADEWTConfig = {}
        FADEWTConfig.OnyxiaHidden = false
        FADEWTConfig.WCBHidden = false
        FADEWTConfig.SongflowerHidden = false
        FADEWTConfig.YellDisabled = false
        FADEWTConfig.Debug = false
        FADEWTConfig.Version = FADEWT.VERSION
    end

    if FADEWTConfig.Version == nil then
        FADEWTConfig.Version = FADEWT.VERSION - 1
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

