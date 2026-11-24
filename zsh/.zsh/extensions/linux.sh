##
## Linux aliases and configurations
##

##
## Environment Variables
##
if (( $+commands[zeditor] )) && ! (( $+commands[zed] )); then
	export EDITOR='zeditor'
	export VISUAL='zeditor'
else
	export EDITOR='zed'
	export VISUAL='zed'
fi
# Omarchy's gcr agent, except in an ssh session that forwarded its own agent.
if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then
	[[ -n $SSH_CONNECTION && -S ${SSH_AUTH_SOCK:-} ]] || export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
fi

##
## General PATH changes
##
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -f "$HOME/.local/share/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/.local/share/google-cloud-sdk/path.zsh.inc"

alias spotify='spotify --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland'
# Arch's zed package installs the binary as zeditor.
(( $+commands[zeditor] )) && alias zed=zeditor

# Hyprland control helper: always target the most recent live instance socket.
function hctl() {
	local sig
	sig="$(command ls -1t /run/user/$UID/hypr/*/.socket.sock 2>/dev/null | head -n1 | xargs -r dirname | xargs -r basename)"
	if [[ -z "$sig" ]]; then
		echo "No active Hyprland socket found"
		return 1
	fi
	HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl "$@"
}
