local ConfigKey = "fadewt"

local options = {
	type = "group",
	name = "FADE World Timers",
	args = {
        Songflower = {
            order = 0,
            type = "toggle",
            name = "Hide Songflower timers",
            desc = "If checked Songflowers are hidden",
            get = function() return FADEWTConfig.SongflowerHidden end,
            set = function(_, value) FADEWTConfig.SongflowerHidden = value; ReloadUI() end,
        },
        WhipperRoot = {
            order = 0,
            type = "toggle",
            name = "Hide Whipper Root timers",
            desc = "If checked Whipper Root are hidden",
            get = function() return FADEWTConfig.WhipperRootHidden end,
            set = function(_, value) FADEWTConfig.WhipperRootHidden = value; ReloadUI() end,
        },
        WCB = {
            order = 0,
            type = "toggle",
            name = "Hide WCB timers",
            desc = "If checked WCB timers are hidden",
            get = function() return FADEWTConfig.WCBHidden end,
            set = function(_, value) FADEWTConfig.WCBHidden = value; ReloadUI() end,
        },
        Onyxia = {
            order = 0,
            type = "toggle",
            name = "Hide Onyxia timers",
            desc = "If checked Onyxia timers are hidden",
            get = function() return FADEWTConfig.OnyxiaHidden end,
            set = function(_, value) FADEWTConfig.OnyxiaHidden = value; ReloadUI() end,
        },
        Nefarian = {
            order = 0,
            type = "toggle",
            name = "Hide Nefarian timers",
            desc = "If checked Nefarian timers are hidden",
            get = function() return FADEWTConfig.NefarianHidden end,
            set = function(_, value) FADEWTConfig.NefarianHidden = value; ReloadUI() end,
        },
        BroadcastYELL = {
            order = 0,
            type = "toggle",
            name = "Toggle broadcasting to YELL",
            desc = "If checked addon does not broadcast to YELL",
            get = function() return FADEWTConfig.YellDisabled end,
            set = function(_, value) FADEWTConfig.YellDisabled = value; ReloadUI() end,
        },
        Debug = {
            order = 0,
            type = "toggle",
            name = "Toggle Debug",
            desc = "If checked you will get debug messages in your chat (for testing only)",
            get = function() return FADEWTConfig.Debug end,
            set = function(_, value) FADEWTConfig.Debug = value; ReloadUI() end,
        }
    }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable(ConfigKey, options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ConfigKey, "FADE World Timers")