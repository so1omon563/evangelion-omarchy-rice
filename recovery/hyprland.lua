-- Static recovery entry point: packaged Omarchy defaults only.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")
require("default.hypr.omarchy")
require("default.hypr.toggles")

-- This remains available even when the user shell and plugins cannot load.
o.bind("SUPER + ALT + R", "Exit Evangelion recovery mode", "magi-recovery exit")
