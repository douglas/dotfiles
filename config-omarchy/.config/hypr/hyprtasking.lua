-- Hyprtasking's plugin actions are registered at runtime under hl.plugin.
-- Keep the bindings in the Omarchy Lua layer; the plugin enters and exits the
-- submap itself as the overview becomes interactive.
-- Plugin loading triggers a config reload; apply profile values once its
-- namespace and registered config keys are available.
if hl.plugin.hyprtasking then
  require("default.hypr.require_optional").module("hypr.hyprtasking_profile")
end

local function hyprtasking_action(name, argument)
  return function()
    local plugin = hl.plugin.hyprtasking
    if not plugin or not plugin[name] then
      error("Hyprtasking is not loaded")
    end

    if argument == nil then
      plugin[name]()
    else
      plugin[name](argument)
    end
  end
end

hl.unbind("CTRL + UP")
hl.unbind("CTRL + DOWN")
hl.unbind("mouse:275")
o.bind("CTRL + UP", "Mission Control", hyprtasking_action("toggle", "all"))
o.bind("CTRL + DOWN", "Mission Control", hyprtasking_action("toggle", "all"))
o.bind("mouse:275", nil, hyprtasking_action("toggle", "all"), { mouse = true })

hl.define_submap("hyprtasking", function()
  o.bind("LEFT", nil, hyprtasking_action("select", "left"))
  o.bind("RIGHT", nil, hyprtasking_action("select", "right"))
  o.bind("UP", nil, hyprtasking_action("select", "up"))
  o.bind("DOWN", nil, hyprtasking_action("select", "down"))

  for workspace = 1, 9 do
    o.bind(tostring(workspace), nil, hyprtasking_action("select", tostring(workspace)))
  end

  o.bind("RETURN", nil, hyprtasking_action("commit"))
  o.bind("ESCAPE", nil, hyprtasking_action("toggle", "cursor"))
end)
