##
## Linux aliases and configurations
##

##
## Environment Variables
##
export EDITOR='zed'
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"

##
## General PATH changes
##
export PATH="$HOME/.bun/bin:$PATH"

alias spotify='spotify --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland'

# Hyprland control helper: always target the most recent live instance socket.
function hctl() {
	local sig
	sig="$(ls -1t /run/user/$UID/hypr/*/.socket.sock 2>/dev/null | head -n1 | xargs dirname | xargs basename)"
	if [[ -z "$sig" ]]; then
		echo "No active Hyprland socket found"
		return 1
	fi
	HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl "$@"
}
