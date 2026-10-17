#!/bin/sh
# Restart xremap after resume so it re-grabs input devices
# (USB devices get new /dev/input/eventN paths after wake, so xremap must re-grab them).
# Prefer the hardened system unit; otherwise restart each logged-in user's unit.
case "$1" in
    post)
        sleep 2
        if /usr/bin/systemctl cat xremap-system.service >/dev/null 2>&1; then
            /usr/bin/systemctl restart xremap-system.service
        else
            for user in $(/usr/bin/loginctl list-users --no-legend | awk '{print $2}'); do
                /usr/bin/systemctl --user -M "$user@" restart xremap.service 2>/dev/null || true
            done
        fi
        ;;
esac
