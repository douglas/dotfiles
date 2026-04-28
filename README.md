# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), supporting macOS and Linux (desktop & laptop).

## How it works

Each top-level directory is a **stow package** — running `stow <package>` symlinks its contents into `$HOME`. Configs are layered so shared settings live in one place while OS- and hardware-specific overrides stay separate:

```
config/                 # Shared app configs (bat, nvim, ghostty, zellij, yazi, etc.)
config-linux/           # Linux-only system files (udev rules, systemd hooks)
config-macos/           # macOS-only configs (Cursor editor)
config-omarchy/         # Omarchy/Hyprland base (quickshell, waybar, walker, keybindings)
config-omarchy-desktop/ # Desktop overrides (font size, window dimensions)
config-omarchy-laptop/  # Laptop overrides (font size, window dimensions)
config-fedora-desktop/  # Fedora/GNOME desktop (future)
config-fedora-laptop/   # Fedora/GNOME laptop (future)
```

On Linux, profile detection uses `hostnamectl chassis` to determine whether to stow `config-omarchy-desktop` or `config-omarchy-laptop`.

**Ghostty** uses `config-file = machine` in the shared config to include per-machine overrides (font size, window dimensions) from a separate `machine` file — avoiding Stow conflicts.

## Installation

```sh
# Linux desktop (default)
./install.sh

# Linux laptop
PROFILE=laptop ./install.sh

# macOS
./install.sh
```

The install script stows all packages and symlinks `git-cob` into `/usr/local/bin`.

## Updating (Linux)

The `update-dotfiles` script handles day-to-day updates:

1. Pulls latest changes from both public and private dotfiles repos
2. Re-stows all packages (auto-detects desktop vs laptop)
3. Installs system files (udev rules, systemd sleep hooks)
4. Reloads udev rules and restarts the xremap service

```sh
update-dotfiles
```

## Stow packages

| Package | Contents |
|---|---|
| `stow` | `.stow-global-ignore` — controls which files stow skips |
| `bin` | Scripts in `~/.bin`: `git-cob`, `update-dotfiles`, `install-tools.sh`, and others |
| `git` | `.gitconfig` and `.gitignore` — delta pager, difftastic, aliases, SSH signing |
| `zsh` | `.zshrc` and `~/.zsh/` — extensions (git, fzf, networking, Rails), Catppuccin theme |
| `config` | Shared `~/.config/` for bat, bottom, btop, delta, ghostty, nvim, yazi, zed, zellij, starship |
| `config-linux` | System files: xremap config/service, sleep hook, Keychron udev rule |
| `config-macos` | Cursor editor settings and keybindings |
| `config-omarchy` | Hyprland base config, Quickshell, Waybar, Walker, Omarchy hooks and theming |
| `config-omarchy-desktop` | Ghostty machine config, Zed settings, Hyprland envs for desktop |
| `config-omarchy-laptop` | Ghostty machine config, Zed settings, Hyprland envs/monitors for laptop |
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
- [xremap](https://github.com/xremap/xremap) — macOS-style keybindings on Linux (Super as Cmd), with separate mappings for terminal and GUI apps
- udev rules for Keychron keyboard HID access
- systemd sleep hook to restart xremap after suspend/resume

## Theme

[Catppuccin Mocha](https://catppuccin.com/) is used consistently across all apps: Ghostty, bat, delta, nvim, zsh syntax highlighting, and fsh.

## macOS extras

The `Brewfile` manages Homebrew dependencies — CLI tools (bat, eza, ripgrep, starship, zoxide, etc.), casks (1Password, Firefox, Chrome, Obsidian, Slack, Spotify, etc.), and VS Code extensions.
