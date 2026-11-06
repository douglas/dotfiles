# Login environment for POSIX shells. uwsm sources this file before it starts
# Hyprland, and any error here stops the desktop session from starting. So
# every line checks that its file or directory exists first.
#
# Installers (rustup, uv, LM Studio, JetBrains Toolbox) append lines here.
# Because this file is stowed, those edits show up in `git status` of
# ~/.public_dotfiles: rewrite them in the guarded form below before committing.

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

for profile_dir in "$HOME/.lmstudio/bin" "$HOME/.local/share/JetBrains/Toolbox/scripts"; do
  if [ -d "$profile_dir" ]; then
    case ":$PATH:" in
      *":$profile_dir:"*) ;;
      *) PATH="$PATH:$profile_dir" ;;
    esac
  fi
done
unset profile_dir
export PATH

# LM Studio adds this exact block on first launch unless it finds it, so keep
# it verbatim (it cannot fail: it only appends a PATH entry).
# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/douglas/.lmstudio/bin"
# End of LM Studio CLI section
