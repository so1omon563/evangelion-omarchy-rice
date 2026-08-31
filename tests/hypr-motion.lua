local root = arg[0]:match("(.*/)tests/hypr%-motion.lua$") or "./"
local expected = arg[1]
local configs, animations = {}, {}

hl = {
  config = function(value) table.insert(configs, value) end,
  curve = function() end,
  animation = function(value) animations[value.leaf] = value end,
}

local previous = os.getenv
os.getenv = function(key)
  if key == "EVANGELION_MOTION_MODE" then return expected end
  return previous(key)
end
dofile(root .. "hypr/looknfeel.lua")

assert(#configs == 1)
local config = configs[1]
if expected == "full" then
  assert(config.animations.enabled == true and config.decoration.blur.enabled == true)
  assert(animations.windowsIn.enabled == true and animations.windowsIn.style == "popin 94%")
  assert(animations.workspaces.enabled == true and animations.workspaces.style == "slide")
  assert(animations.layersIn.enabled == true and animations.layersOut.enabled == true)
elseif expected == "reduced" then
  assert(config.animations.enabled == true and config.decoration.blur.enabled == false)
  assert(animations.windowsIn.enabled == false and animations.workspaces.enabled == false)
  assert(animations.layersIn.enabled == false and animations.layersOut.enabled == false)
  assert(animations.fade.enabled == true and animations.border.enabled == true)
elseif expected == "off" then
  assert(config.animations.enabled == false and config.decoration.blur.enabled == false)
  assert(next(animations) == nil)
else
  error("unsupported fixture")
end
