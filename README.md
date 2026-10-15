# dotfiles

Personal dotfiles managed with [dotlayer](https://github.com/douglas/dotlayer), supporting macOS and Omarchy desktop/laptop machines.

## How it works

Each top-level directory is a dotlayer package. Dotlayer detects OS, profile, distro, and machine tags, then runs GNU Stow in the right order so shared settings live in one place while OS-, distro-, profile-, and model-specific overrides stay separate:

```
config/                 # Shared app configs (bat, ghostty, zellij, yazi, etc.)
config-linux/           # Linux-only system files (udev rules, systemd hooks)
config-macos/           # macOS-only configs (Cursor editor)
config-omarchy/         # Shared Omarchy base (nvim, Hyprland Lua, keybindings)
config-omarchy-desktop/ # Desktop overrides (font size, window dimensions)
config-omarchy-laptop/  # Shared laptop glue (monitor/profile entrypoints)
config-omarchy-laptop-t1g/ # T1G laptop model overrides
config-omarchy-laptop-t14/ # T14 laptop model overrides
config-fedora-desktop/  # Fedora/GNOME desktop (future)
config-fedora-laptop/   # Fedora/GNOME laptop (future)
```

On Linux, profile detection uses `hostnamectl chassis` to determine whether to stow desktop or laptop profile packages. Machine tags such as `t1g` and `t14` come from `~/.config/dotlayer/dotlayer.yml`, where each tag has a DMI/model detection command. Use `DOTLAYER_MACHINE=t14` to force a tag for testing.

**Ghostty, Kitty, Alacritty, Waybar, and Hyprland** use app-level includes or source files named `machine`/`machine-*` for model-specific values. That keeps Stow packages additive and avoids conflicts between shared Omarchy config and machine overrides.

## Installation

```sh
# Auto-detect current machine
./install.sh

# Test a laptop model without changing links
DOTLAYER_PROFILE=laptop DOTLAYER_MACHINE=t14 ./install.sh --dry-run --verbose

# macOS also uses dotlayer
./install.sh --dry-run
```

The install script is a thin wrapper around `dotlayer install`. It does not contain package-selection logic.

## Updating (Linux)

```sh
update-dotfiles
```

`update-dotfiles` is a thin wrapper around `dotlayer update`, which pulls configured repos, restows matching packages, and runs configured system-file hooks.

On Omarchy, upgrading the `hyprland` package also rebuilds the local
Hyprtasking checkout against the new headers. It hot-reloads only when the
running compositor matches; otherwise the freshly built plugin is loaded at
the next Hyprland start. Failures are logged in
`~/.local/state/hyprtasking/rebuild-after-hyprland-upgrade.log`.

The Omarchy post-update hook restores all detected `config-omarchy` layers,
including the laptop model, using dotlayer's resolver. It preserves migration
changes for review and skips adoption when the checkout has uncommitted work.
Hyprtasking rebuild checks still run when adoption is skipped.

Shell layout and idle preferences live in `config-omarchy/.config/omarchy/shell.json`;
supported font, spacing, and bar sizing overrides live in `shell.toml`.
Hyprtasking gestures are loaded from each profile's `hyprtasking_profile.lua`.
The T1G layer also stores its monitor defaults and the saved laptop-only
hyprmoncfg profile. Generated `hyprmoncfg-monitors.lua` remains machine-local
and loads last, so layouts chosen through hyprmoncfg take precedence.

## Stow packages

| Package | Contents |
|---|---|
| `stow` | `.stow-global-ignore` — controls which files stow skips |
| `bin` | Scripts in `~/.bin`: `git-cob`, `update-dotfiles`, `install-tools.sh`, and others |
| `git` | `.gitconfig` and `.gitignore` — delta pager, difftastic, aliases, SSH signing |
| `zsh` | `.zshrc` and `~/.zsh/` — extensions (git, fzf, networking, Rails), Catppuccin theme |
| `config` | Shared `~/.config/` for bat, bottom, btop, delta, ghostty, yazi, zed, zellij, starship |
| `config-linux` | System files: split xremap services, hardening installer, sleep hook, Keychron udev rule |
| `config-macos` | Cursor editor settings and keybindings |
| `config-omarchy` | Shared Omarchy config: Neovim, Hyprland Lua, Neosh integration, Omarchy hooks, audio policy, startup. Legacy Waybar, Walker, and Hyprland `.conf` files remain excluded from Stow as migration reference. |
| `config-omarchy-desktop` | Ghostty machine config, Zed settings, Hyprland envs for desktop |
| `config-omarchy-laptop` | Shared laptop monitor/profile entrypoints |
| `config-omarchy-laptop-t1g` | T1G laptop terminal, Waybar, and Hyprland model overrides |
| `config-omarchy-laptop-t14` | T14 laptop terminal, Waybar, and Hyprland model overrides |
| `config-fedora-desktop` | Fedora/GNOME desktop config (future) |
| `config-fedora-laptop` | Fedora/GNOME laptop config (future) |

## Applications

**Terminal & shell**
- [Ghostty](https://ghostty.org/) — terminal emulator (profile-specific font size and window dimensions)
- [Zellij](https://zellij.dev/) — terminal multiplexer
- [Zsh](https://www.zsh.org/) — shell with extensions for git, fzf, Rails, networking
- [Starship](https://starship.rs/) — cross-shell prompt
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder
- [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd`

**Editors**
- [Neovim](https://neovim.io/) — configured with [LazyVim](https://www.lazyvim.org/)
- [Zed](https://zed.dev/) — with Ruby snippets and custom tasks
- [Cursor](https://cursor.sh/) — macOS only (settings + keybindings)

**Dev tools**
- [Git](https://git-scm.com/) — [delta](https://github.com/dandavison/delta) pager, [difftastic](https://difftastic.wilfred.me/) diffs, `git-cob` (checkout branch with fuzzy search), SSH commit signing
- [bat](https://github.com/sharkdp/bat) — `cat` replacement (aliased)
- [eza](https://eza.rocks/) — `ls` replacement (aliased)
- [yazi](https://yazi-rs.github.io/) — terminal file manager
- [bottom](https://clementtsang.github.io/bottom/) — `top` replacement (aliased)
- [btop](https://github.com/aristocratos/btop) — system monitor
- [lazydocker](https://github.com/jesseduffield/lazydocker) — Docker TUI

**System (Linux)**
- [xremap](https://github.com/xremap/xremap) — macOS-style keybindings on Linux, with a privileged input daemon and an unprivileged Hyprland bridge
- udev rules for Keychron keyboard HID access
- systemd sleep hook to restart xremap after suspend/resume

The xremap security migration is deliberately staged so the working remapper is
not stopped before the replacement is ready:

```sh
sudo ~/.public_dotfiles/config-linux/usr/local/sbin/harden-xremap install
# Reboot and test all remaps.
sudo ~/.public_dotfiles/config-linux/usr/local/sbin/harden-xremap status
sudo ~/.public_dotfiles/config-linux/usr/local/sbin/harden-xremap finalize
# Reboot again to discard the old login session's input-group credentials.
```

## Theme

[Catppuccin Mocha](https://catppuccin.com/) is used consistently across all apps: Ghostty, bat, delta, nvim, zsh syntax highlighting, and fsh.

## macOS extras

The `Brewfile` manages Homebrew dependencies — CLI tools (bat, eza, ripgrep, starship, zoxide, etc.), casks (1Password, Firefox, Chrome, Obsidian, Slack, Spotify, etc.), and VS Code extensions.
