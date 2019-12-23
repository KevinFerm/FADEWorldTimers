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

-- Fires the OnUnitAura on every WorldTimer that has the function when UNIT_AURA event is fired
function FADEWT:OnUnitAura(self, unit)
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.OnUnitAura ~= nil then
            Timer:OnUnitAura(unit)
        end
    end
end

-- Sets up SavedVariabled for all registered timers
function FADEWT:SetupDB()
    for _, Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.SetupDB ~= nil then
            Timer:SetupDB()
        end
    end
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

-- Fires on every event
-- Todo: Add every needed event here
function FADEWT:HandleEvent(event, ...)
    if event == "UNIT_AURA" then
        local unit = ...
        FADEWT:OnUnitAura(self, unit)
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

function FADEWT:BroadcastTimers()
    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.BroadcastTimers ~= nil then
            Timer:BroadcastTimers()
        end
    end
end

-- Initializes our addon
function FADEWT:Init()
    -- Create an empty DB if need be
    FADEWT:SetupDB()

    for _,Timer in ipairs(FADEWT.WorldTimers) do
        if Timer.Init ~= nil then
            Timer:Init()
        end
    end

    --Songbird:createNodes()
    local Frame = CreateFrame("Frame", nil, UIParent)

    -- Update the active songflower timers every second
    AceTimer:ScheduleRepeatingTimer(FADEWT.Tick, 1)

    -- Register event on UNIT_AURA so we can check if player got Songflower
    Frame:RegisterEvent("UNIT_AURA")
    Frame:RegisterEvent("CHAT_MSG_LOOT")
    Frame:SetScript("OnEvent", FADEWT.HandleEvent)
    --Comm:RegisterComm("FADEWorldTimers", FADEWT.RecvTimers)
end
-- Run our initialize script
FADEWT:Initialize()

-- Set our addon object as global
_G["FADEWT"] = FADEWT
------ END INITIALIZE ADDON CORE
---------------------------

