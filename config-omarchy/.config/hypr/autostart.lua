-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Wait for the shell's status notifier before starting the Zscaler tray.
o.launch_on_start("zscaler-tray-after-status-notifier")

-- Built locally against the installed Hyprland headers. This is kept outside
-- Omarchy's defaults so package upgrades do not replace the plugin setup.
o.launch_on_start("hyprctl plugin load $HOME/src/hyprtasking/build/libhyprtasking.so")
