-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Personal overrides load after Omarchy defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("default.hypr.toggles")

-- Keep Plex TUI floating, but nearly fill the active monitor.
o.window({ class = "com\\.mitchellh\\.ghostty", title = "^plex-tui$" }, {
  float = true,
  center = true,
  size = { "(monitor_w-100)", "(monitor_h-100)" },
})

-- MAGI presentation mode: establish safe floating defaults. The launcher then
-- refines size and placement from the active wallpaper's composition profile.
o.window("^org\\.omarchy\\.magi\\.fastfetch$", {
  float = true,
  workspace = "5 silent",
  size = { "(monitor_w*9/20)", 440 },
  move = { 14, 48 },
  opacity = "0.94 0.90",
})

o.window("^org\\.omarchy\\.magi\\.btop$", {
  float = true,
  workspace = "5 silent",
  size = { "(monitor_w*9/20)", 550 },
  move = { 14, 510 },
  opacity = "0.94 0.90",
})
