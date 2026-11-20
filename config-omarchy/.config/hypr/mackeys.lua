-- macOS-style shortcuts in Hyprland, replacing xremap.
--
-- Left Alt is Cmd: the mackeys:mac XKB option (~/.config/xkb) turns it into
-- Hyper on Mod3, Caps Lock into Control, and the ISO key next to Left Shift
-- into Shift. Each Cmd chord below picks an action by the focused app:
--   "CTRL + C"           send that shortcut to the app
--   { wm = "SUPER + H" } run whatever Hyprland binds to that chord (Omarchy's
--                        defaults plus your overrides), so nothing is copied
--   { exec = "cmd" }     run a command
--   { seq = { ... } }    send several shortcuts in a row
--
-- hyprland.lua calls record() before Omarchy's defaults load, so every bind
-- is captured, and setup() at the end.

local M = {}

-- Chords use xremap-style names; this maps them to XKB keysym names.
local key_names = {
  Enter = "Return", Backspace = "BackSpace", Space = "space", Grave = "grave",
  Equal = "equal", Minus = "minus", Comma = "comma", Slash = "slash",
  Backslash = "backslash", LeftBrace = "bracketleft", RightBrace = "bracketright",
  PageUp = "Page_Up", PageDown = "Page_Down",
}

local function normalize(keys)
  local parts = {}
  for part in keys:gsub("%+", " "):gmatch("%S+") do
    parts[#parts + 1] = part:upper()
  end
  local key = table.remove(parts)
  table.sort(parts)
  parts[#parts + 1] = key
  return table.concat(parts, "+")
end

-- Digits bind by keycode, like Omarchy's workspace keys, so Shift + 1 still
-- matches instead of turning into "exclam".
local function bind_key(key)
  if key:match("^%d$") then
    return "code:" .. (key == "0" and 19 or 9 + tonumber(key))
  end
  return key_names[key] or key
end

function M.record()
  _G.mackeys_binds = {}
  _G.mackeys_original_bind = _G.mackeys_original_bind or hl.bind
  _G.mackeys_original_unbind = _G.mackeys_original_unbind or hl.unbind

  hl.bind = function(keys, dispatcher, opts)
    if type(keys) == "string" then
      _G.mackeys_binds[normalize(keys)] = dispatcher
    end
    return _G.mackeys_original_bind(keys, dispatcher, opts)
  end

  hl.unbind = function(keys)
    if type(keys) == "string" then
      _G.mackeys_binds[normalize(keys)] = nil
    end
    return _G.mackeys_original_unbind(keys)
  end
end

local function run_dispatcher(dispatcher)
  if type(dispatcher) == "function" then
    dispatcher()
  elseif dispatcher then
    hl.dispatch(dispatcher)
  end
end

-- "CTRL SHIFT + Left" -> mods "CTRL SHIFT", key "Left".
local function split_shortcut(shortcut)
  local mods, key = shortcut:match("^(.-)%s*%+%s*([^+]+)$")
  if not key then
    return "", key_names[shortcut] or shortcut
  end
  return mods:gsub("%s*%+%s*", " "):gsub("ALTGR", "MOD5"), key_names[key] or key
end

-- Down and up as separate events: Hyprland's send_shortcut can leave keys
-- stuck. Same workaround as Omarchy's default/hypr/bindings/clipboard.lua.
local function send(shortcuts)
  for index, shortcut in ipairs(shortcuts) do
    local mods, key = split_shortcut(shortcut)
    local delay = (index - 1) * 40
    local function down()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    end
    local function up()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end
    if delay == 0 then down() else hl.timer(down, { timeout = delay, type = "oneshot" }) end
    hl.timer(up, { timeout = delay + 20, type = "oneshot" })
  end
end

local function run(action)
  if type(action) == "string" then
    send({ action })
  elseif action.seq then
    send(action.seq)
  elseif action.exec then
    hl.exec_cmd(action.exec)
  elseif action.wm then
    run_dispatcher(_G.mackeys_binds[normalize(action.wm)])
  end
end

-- ===========================================================================
-- Profiles. A chord's modifiers are written in this order: CMD CTRL SUPER SHIFT.
-- ===========================================================================

local global = {
  ["CMD CTRL + n"] = { wm = "SUPER + Return" },
  ["CMD CTRL + j"] = { wm = "SUPER CTRL + j" },
}

-- Window manager and launcher shortcuts shared by every app.
local wm = {
  ["CMD + Space"] = { exec = "omacast toggle" },
  ["CMD SHIFT + Space"] = { wm = "SUPER + Space" },
  ["CMD + q"] = { wm = "SUPER + w" },
  ["CMD + h"] = { wm = "SUPER + h" },
  ["CMD + m"] = { wm = "SUPER + m" },
  ["CMD + j"] = { wm = "SUPER + j" },
  ["CMD + Grave"] = { wm = "SUPER + grave" },
  ["CMD SHIFT + v"] = { wm = "SUPER CTRL + v" },
  ["CMD + Tab"] = { wm = "SUPER + Tab" },
  ["CMD SHIFT + Tab"] = { wm = "SUPER SHIFT + Tab" },
  ["CMD SUPER + Left"] = { wm = "SUPER SHIFT + Tab" },
  ["CMD SUPER + Right"] = { wm = "SUPER + Tab" },
  ["CMD CTRL + Left"] = { wm = "SUPER SHIFT + Tab" },
  ["CMD CTRL + Right"] = { wm = "SUPER + Tab" },
  ["CMD SHIFT + 3"] = { exec = "omarchy-capture-screenshot fullscreen" },
  ["CMD SHIFT + 4"] = { exec = "omarchy-capture-screenshot region" },
  ["CMD SHIFT + 5"] = { exec = "omarchy-menu toggle capture" },
}
for _, direction in ipairs({ "Left", "Right", "Up", "Down" }) do
  wm["CMD + " .. direction] = { wm = "SUPER + " .. direction }
  wm["CMD SHIFT + " .. direction] = { wm = "SUPER SHIFT + " .. direction }
end
for digit = 1, 9 do
  wm["CMD + " .. digit] = { wm = "SUPER + " .. bind_key(tostring(digit)) }
  -- Cmd+Shift+3/4/5 are screenshots, so those three moves add Ctrl.
  local move = (digit >= 3 and digit <= 5) and "CMD CTRL SHIFT + " or "CMD SHIFT + "
  wm[move .. digit] = { wm = "SUPER SHIFT + " .. bind_key(tostring(digit)) }
end

-- Terminals: Ctrl+Shift for clipboard and tabs, so Ctrl stays a control char.
local terminal = {
  ["CMD + c"] = "CTRL SHIFT + c", ["CMD + v"] = "CTRL SHIFT + v",
  ["CMD + t"] = "CTRL SHIFT + t", ["CMD + w"] = "CTRL SHIFT + w",
  ["CMD + n"] = "CTRL SHIFT + n", ["CMD + f"] = "CTRL SHIFT + f",
  ["CMD + g"] = "CTRL SHIFT + g", ["CMD + k"] = "CTRL SHIFT + k",
  ["CMD + a"] = "CTRL + a", ["CMD + e"] = "CTRL + e",
  ["CMD + Backspace"] = "CTRL + u",
  ["CMD + Equal"] = "CTRL + Equal", ["CMD + Minus"] = "CTRL + Minus",
  ["CMD + 0"] = "CTRL + 0", ["CMD + Comma"] = "CTRL + Comma",
  ["CMD + Enter"] = "CTRL + Return",
  ["CMD + s"] = { wm = "SUPER + s" }, ["CMD + o"] = { wm = "SUPER + o" },
  ["CTRL + Left"] = "CTRL SHIFT + Left", ["CTRL + Right"] = "CTRL SHIFT + Right",
  ["ALTGR + Left"] = "CTRL SHIFT + Left", ["ALTGR + Right"] = "CTRL SHIFT + Right",
}

local spotify = {
  ["CMD + q"] = "CTRL SHIFT + q", ["CMD + w"] = "CTRL SHIFT + q",
}

-- Herdr is a terminal, but only these keys differ from the default profile.
local herdr = {
  ["CMD + c"] = "CTRL SHIFT + c", ["CMD + v"] = "CTRL SHIFT + v",
  ["CMD + t"] = "CTRL SHIFT + t", ["CMD + w"] = "CTRL SHIFT + w",
  ["CMD + n"] = "CTRL SHIFT + n", ["CMD + f"] = "CTRL SHIFT + f",
  ["CMD + k"] = "CTRL SHIFT + k", ["CMD + Backspace"] = "CTRL + u",
  ["CMD CTRL + Up"] = "CTRL SHIFT + PageUp", ["CMD CTRL + Down"] = "CTRL SHIFT + PageDown",
}

-- Every other app: Cmd is Ctrl.
local default = {
  ["CMD + q"] = { wm = "SUPER + w" },
  ["CMD + Backspace"] = { seq = { "SHIFT + Home", "Delete" } },
  ["CMD SHIFT + RightBrace"] = "CTRL + PageDown",
  ["CMD SHIFT + LeftBrace"] = "CTRL + PageUp",
  ["CTRL + Left"] = "CTRL + PageUp", ["CTRL + Right"] = "CTRL + PageDown",
  ["ALTGR + Left"] = "CTRL + PageUp", ["ALTGR + Right"] = "CTRL + PageDown",
}
for key in ("c v x z a f s o p n w t b i u r l d k e g Comma Slash LeftBrace RightBrace Enter"):gmatch("%S+") do
  default["CMD + " .. key] = "CTRL + " .. key
end
for key in ("z s t n p f o k l h Backslash"):gmatch("%S+") do
  default["CMD SHIFT + " .. key] = "CTRL SHIFT + " .. key
end

local terminals = {
  ["com.mitchellh.ghostty"] = true, Alacritty = true, kitty = true, foot = true, rio = true,
}

-- First match wins, like xremap's keymap order.
local function profiles_for(window)
  local class = window and window.class or ""
  if terminals[class] then
    return { global, terminal, wm }
  elseif class == "spotify" or class == "Spotify" then
    return { global, spotify, wm }
  elseif class == "herdr-app" then
    return { global, herdr, default, wm }
  end
  return { global, default, wm }
end

local function hyprland_chord(chord)
  local mods, key = chord:match("^(.-)%s*%+%s*(%S+)$")
  -- Right Alt is AltGr (Level3 on Mod5) with the intl layout.
  mods = mods:gsub("CMD", "MOD3"):gsub("ALTGR", "MOD5"):gsub("%s+", " + ")
  return mods .. " + " .. bind_key(key)
end

function M.setup()
  local options = hl.get_config("input.kb_options")
  options = type(options) == "string" and options or ""
  if not options:find("mackeys:mac", 1, true) then
    hl.config({ input = { kb_options = (options ~= "" and options .. "," or "") .. "mackeys:mac" } })
  end

  local chords = {}
  for _, profile in ipairs({ global, wm, terminal, spotify, herdr, default }) do
    for chord in pairs(profile) do
      chords[chord] = true
    end
  end

  for chord in pairs(chords) do
    local plain = not chord:find("CMD", 1, true)
    hl.bind(hyprland_chord(chord), function()
      for _, profile in ipairs(profiles_for(hl.get_active_window())) do
        if profile[chord] then
          return run(profile[chord])
        end
      end
      -- Plain chords like Ctrl+Left are bound globally, so pass them on
      -- untouched to apps without a rule.
      if plain then
        send({ chord })
      end
    end, { description = "mackeys: " .. chord })
  end

  -- Cmd+click is Ctrl+click (open links in a new tab). Hold a synthetic Ctrl
  -- for the click; non_consuming lets the click itself reach the app.
  local function ctrl(state)
    return function()
      hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "Control_L", state = state }))
    end
  end
  o.bind_hold("MOD3 + mouse:272", "mackeys: Cmd click", ctrl("down"),
    "mackeys: Cmd click release", ctrl("up"), { non_consuming = true })
end

return M
