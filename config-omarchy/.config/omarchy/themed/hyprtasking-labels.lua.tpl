-- Hyprtasking overview label colors and effects, generated from the Omarchy theme.
-- theme-set applies this through the Lua API (hyprctl eval) when the loaded
-- plugin build has label options; see hooks/theme-set.
hl.config({
  plugin = {
    hyprtasking = {
      labels = {
        enabled = 1,
        mode = "outlined",
        grid = { mode = "outlined" },
        linear = { mode = "outlined" },

        -- Non-selected labels follow the Omarchy accent; selected labels inherit it
        -- (-1) and are highlighted with a same-color glow.
        text_color = "rgba({{ accent_strip }}ff)",
        selected_text_color = -1,

        -- Same size for every label; the selection stands out by color only.
        point_size = 30,
        selected_emphasis = 1,
        selected_scale = 1.06,
        selected_glow = 1,
        selected_glow_color = -1,
        selected_glow_strength = 0.42,
        selected_glow_spread = 1.7,
        outline_width = 0.85,
        shadow_color = "rgba(000000aa)",
        shadow_offset_x = 1.2,
        shadow_offset_y = 1.2,
        position = "top_right",
        margin = 14,
      },
    },
  },
})
