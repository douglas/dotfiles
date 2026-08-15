-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.env("QS_UI_SCALE_MULTIPLIER", "0.5")
hl.env("QS_BAR_SCALE_MULTIPLIER", "0.5")

hl.monitor({
  output = "desc:Lenovo Group Limited P40WD-40",
  mode = "5120x2160@120",
  position = "auto",
  scale = 2,
})

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
