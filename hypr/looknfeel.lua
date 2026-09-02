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
local function visual_config()
  local home = os.getenv("HOME") or ""
  local handle = io.open(home .. "/.config/omarchy/visual.json", "r")
  if not handle then return {} end
  local text = handle:read("*a") or ""
  handle:close()
  local result = {}
  for key, value in text:gmatch('"([%w_]+)"%s*:%s*"([%w_-]+)"') do result[key] = value end
  return result
end

local visual = visual_config()
local gap_profiles = { tight = { 2, 4 }, balanced = { 3, 7 }, open = { 6, 12 } }
local border_profiles = { minimal = 1, standard = 2, strong = 3 }
local blur_profiles = { off = { false, 0, 0 }, subtle = { true, 3, 1 }, balanced = { true, 6, 2 } }
local opacity_profiles = { opaque = 1.0, solid = 0.96, soft = 0.90 }
local animation_profiles = { calm = 0.82, balanced = 1.0, expressive = 1.16 }
local gaps = gap_profiles[visual.gaps] or gap_profiles.balanced
local border_size = border_profiles[visual.borders] or border_profiles.standard
local visual_blur = blur_profiles[visual.blur] or blur_profiles.balanced
local window_opacity = opacity_profiles[visual.opacity] or opacity_profiles.solid
local animation_scale = animation_profiles[visual.animation_intensity] or animation_profiles.balanced
local profiles = {
  off = { animations = false, blur = false },
  reduced = { animations = true, blur = false },
  full = { animations = true, blur = true },
}
local profile = profiles[mode]

hl.config({
  general = {
    gaps_in = gaps[1],
    gaps_out = gaps[2],
    border_size = border_size,
  },
  decoration = {
    rounding = 3,
    rounding_power = 2,
    dim_inactive = true,
    dim_strength = 0.12,
    active_opacity = window_opacity,
    inactive_opacity = math.max(0.82, window_opacity - 0.04),
    shadow = {
      enabled = true,
      range = 14,
      render_power = 2,
      color = "rgba(060408aa)",
    },
    blur = {
      enabled = profile.blur and visual_blur[1],
      size = visual_blur[2],
      passes = visual_blur[3],
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
  hl.animation({ leaf = "windows", enabled = true, speed = 5.2 * animation_scale, bezier = "magiSnap" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.8 * animation_scale, bezier = "magiSnap", style = "popin 94%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.2 * animation_scale, bezier = "magiExit", style = "popin 96%" })
  hl.animation({ leaf = "border", enabled = true, speed = 4.0 * animation_scale, bezier = "magiLinear" })
  hl.animation({ leaf = "fade", enabled = true, speed = 4.6 * animation_scale, bezier = "magiSnap" })
  hl.animation({ leaf = "layers", enabled = true, speed = 5.2 * animation_scale, bezier = "magiSnap" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 5.0 * animation_scale, bezier = "magiSnap", style = "slide" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 4.0 * animation_scale, bezier = "magiExit", style = "slide" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 4.8 * animation_scale, bezier = "magiSnap", style = "slide" })
  hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.2 * animation_scale, bezier = "magiSnap", style = "slidevert" })
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
