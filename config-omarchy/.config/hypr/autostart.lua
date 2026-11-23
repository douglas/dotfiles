-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Wait for the shell's status notifier before starting the Zscaler tray.
o.launch_on_start("zscaler-tray-after-status-notifier")

-- 1Password multiplies GNOME's text-scaling-factor into its own scale, so at
-- text size 11 its content fills only ~91% of each window. Default gsettings
-- keep it at the plain monitor scale. Started here, not from its own "Start at
-- login" entry, because 1Password rewrites that file.
-- See omacom/omarchy#12228 and #8574.
o.launch_on_start("env GSETTINGS_BACKEND=memory uwsm-app -- 1password --silent")

-- Built locally against the installed Hyprland headers. This is kept outside
-- Omarchy's defaults so package upgrades do not replace the plugin setup.
o.launch_on_start("hyprctl plugin load $HOME/src/hyprtasking/build/libhyprtasking.so")

-- Omarchy's autostart runs `herdr server`, but this setup removes the herdr
-- terminal app (Install/Omarchy/01-packages.sh), and uwsm-app shows an error
-- notification for a command that isn't installed. Skip that one launch while
-- herdr is missing; it runs again by itself if herdr is ever reinstalled.
-- Omarchy runs its autostart after the whole config has loaded, so wrapping
-- hl.exec_cmd here still catches it.
local herdr_found = os.execute("command -v herdr >/dev/null 2>&1")
_G.omarchy_original_exec_cmd = _G.omarchy_original_exec_cmd or hl.exec_cmd
if herdr_found == true or herdr_found == 0 then
  hl.exec_cmd = _G.omarchy_original_exec_cmd
else
  hl.exec_cmd = function(command, ...)
    if command == o.launch("herdr server") then return end
    return _G.omarchy_original_exec_cmd(command, ...)
  end
end
