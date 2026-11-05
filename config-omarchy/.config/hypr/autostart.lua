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
