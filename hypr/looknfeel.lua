-- Tokyo-3 operations-console geometry and motion.
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
      enabled = true,
      size = 6,
      passes = 2,
      new_optimizations = true,
    },
  },
  animations = { enabled = true },
})

hl.curve("magiSnap", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("magiExit", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })
hl.curve("magiLinear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5.2, bezier = "magiSnap" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.8, bezier = "magiSnap", style = "popin 94%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.2, bezier = "magiExit", style = "popin 96%" })
hl.animation({ leaf = "border", enabled = true, speed = 4.0, bezier = "magiLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 4.6, bezier = "magiSnap" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.8, bezier = "magiSnap", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.2, bezier = "magiSnap", style = "slidevert" })
