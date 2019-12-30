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
        }
    }
}

LibStub("AceConfig-3.0"):RegisterOptionsTable(ConfigKey, options)
LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ConfigKey, "FADE World Timers")