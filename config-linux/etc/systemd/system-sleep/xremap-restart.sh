#!/bin/sh
# Restart the privileged xremap daemon after resume so it re-grabs input devices
# (USB devices get new /dev/input/eventN paths after wake, so xremap must re-grab them)
case "$1" in
    post) sleep 2 && /usr/bin/systemctl restart xremap-system.service ;;
esac
