-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Built locally against the installed Hyprland headers. This is kept outside
-- Omarchy's defaults so package upgrades do not replace the plugin setup.
o.launch_on_start("hyprctl plugin load $HOME/src/hyprtasking/build/libhyprtasking.so")
