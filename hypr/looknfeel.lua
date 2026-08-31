-- Tokyo-3 operations-console geometry and motion. The controller's effective
-- mode includes temporary capture/presentation/game bypass holds; failure to
-- resolve it deliberately falls back to the established v1.1 Full profile.
local function motion_mode()
  local override = os.getenv("EVANGELION_MOTION_MODE")
  if override == "off" or override == "reduced" or override == "full" then
    return override
  end
  local handle = io.popen("magi-motion effective 2>/dev/null")
  if not handle then return "full" end
  local value = handle:read("*l")
  handle:close()
  if value == "off" or value == "reduced" or value == "full" then return value end
  return "full"
end

local mode = motion_mode()
local profiles = {
  off = { animations = false, blur = false },
  reduced = { animations = true, blur = false },
  full = { animations = true, blur = true },
}
local profile = profiles[mode]

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 7,
    border_size = 2,
  },
  decoration = {
    rounding = 3,
    rounding_power = 2,
    dim_inactive = true,
    dim_strength = 0.12,
    shadow = {
      enabled = true,
      range = 14,
      render_power = 2,
      color = "rgba(060408aa)",
    },
    blur = {
      enabled = profile.blur,
      size = 6,
      passes = 2,
      new_optimizations = true,
    },
  },
  animations = { enabled = profile.animations },
})

hl.curve("magiSnap", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("magiExit", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })
hl.curve("magiLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

if mode == "full" then
  -- Stable v1.1 profile: spatial workspace continuity and restrained pop-in.
  hl.animation({ leaf = "windows", enabled = true, speed = 5.2, bezier = "magiSnap" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.8, bezier = "magiSnap", style = "popin 94%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.2, bezier = "magiExit", style = "popin 96%" })
  hl.animation({ leaf = "border", enabled = true, speed = 4.0, bezier = "magiLinear" })
  hl.animation({ leaf = "fade", enabled = true, speed = 4.6, bezier = "magiSnap" })
  hl.animation({ leaf = "layers", enabled = true, speed = 5.2, bezier = "magiSnap" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 5.0, bezier = "magiSnap", style = "slide" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 4.0, bezier = "magiExit", style = "slide" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 4.8, bezier = "magiSnap", style = "slide" })
  hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.2, bezier = "magiSnap", style = "slidevert" })
elseif mode == "reduced" then
  -- No travel, pop/scale, or blur. Short fades retain immediate state context.
  hl.animation({ leaf = "windows", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "windowsIn", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "windowsOut", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "border", enabled = true, speed = 8.0, bezier = "magiLinear" })
  hl.animation({ leaf = "fade", enabled = true, speed = 8.0, bezier = "magiLinear" })
  hl.animation({ leaf = "layers", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "layersIn", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "layersOut", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "workspaces", enabled = false, speed = 1.0, bezier = "magiLinear" })
  hl.animation({ leaf = "specialWorkspace", enabled = false, speed = 1.0, bezier = "magiLinear" })
end
