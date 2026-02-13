#!/bin/sh
# Restart xremap after resume so it re-grabs keyboard devices
# (USB devices get new /dev/input/eventN paths after wake, so xremap must re-grab them)
case "$1" in
    post) sleep 2 && /usr/bin/systemctl --machine=$(id -un)@.host --user restart xremap ;;
esac
