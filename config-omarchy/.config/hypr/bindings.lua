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
o.bind("SUPER + W", "Close window or NeoSH overlay", "$HOME/.bin/omarchy-close-or-killactive")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- xremap translates the physical Cmd/F18 key to Super. Cycle once through
-- each running application, including windows on other workspaces.
local function cycle_global_app(next)
  local applications = {}
  local seen_classes = {}

  for _, window in ipairs(hl.get_windows()) do
    if window.mapped
      and not window.hidden
      and window.workspace
      and window.workspace.id >= 0
      and window.class ~= ""
      and not seen_classes[window.class]
    then
      seen_classes[window.class] = true
      table.insert(applications, window)
    end
  end

  table.sort(applications, function(left, right)
    return left.focus_history_id < right.focus_history_id
  end)

  if #applications <= 1 then
    return
  end

  local active_index = 1
  for index, window in ipairs(applications) do
    if window.active then
      active_index = index
      break
    end
  end

  local target_index = next
    and active_index % #applications + 1
    or (active_index - 2) % #applications + 1
  local target = applications[target_index]

  hl.dispatch(hl.dsp.focus({ window = target }))
  hl.dispatch(hl.dsp.window.bring_to_top({ window = target }))
end

hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
o.bind("SUPER + TAB", "Next global app", function() cycle_global_app(true) end)
o.bind("SUPER + SHIFT + TAB", "Previous global app", function() cycle_global_app(false) end)

pcall(require, "hypr.hyprtasking")

-- Private machine preferences are an optional later layer. Keep the Omarchy
-- module loadable when that layer is absent.
pcall(require, "hypr.personal")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
