-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- F18+Q is remapped to SUPER+W. Close NeoSH overlays before falling back to
-- Omarchy's normal close-window behavior.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window or NeoSH overlay", "$HOME/.local/bin/neosh-close-or-killactive")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- xremap translates the physical Cmd/F18 key to Super. Keep Cmd+Tab as
-- global app cycling without replacing Omarchy's other default bindings.
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
o.bind("SUPER + TAB", "Next global app", "$HOME/.local/bin/hypr-global-app-cycle next")
o.bind("SUPER + SHIFT + TAB", "Previous global app", "$HOME/.local/bin/hypr-global-app-cycle previous")

pcall(require, "hypr.hyprtasking")

-- Private machine preferences are an optional later layer. Keep the Omarchy
-- module loadable when that layer is absent.
pcall(require, "hypr.personal")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
