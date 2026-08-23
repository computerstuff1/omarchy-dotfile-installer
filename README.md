# Omarchy Dotfile Installer

Reproduces a specific [Omarchy](https://omarchy.org) desktop look with one
command. It installs the theme, font, wallpapers, custom bar/menu/clock/
workspaces/lock plugins, terminal and app configs, and a custom SDDM login
screen.

## What it sets up

| Area | Result |
|------|--------|
| Theme | Dracula |
| Font | JetBrainsMono Nerd Font |
| Icon theme | Yaru-red (applied by the Dracula theme) |
| Wallpaper | "They live Desktop.png" (plus 2 others) |
| Status bar | Custom `rob.bar` layout (menu, workspaces, clock, vitals, AI usage bar, tray) |
| Lock screen | Custom `rob.lock` (split-style) |
| Login screen | Custom `my-split` SDDM theme |
| Terminals | foot, ghostty (font size 11) |
| Apps | fastfetch, starship configs |
| Hyprland | monitor (auto-detect), look'n'feel overrides |

## Requirements

- An existing [Omarchy](https://omarchy.org) installation.
- `sudo` access (for the SDDM theme).

## Install

```bash
git clone git@github.com:computerstuff1/omarchy-dotfile-installer.git
cd omarchy-dotfile-installer
./install.sh
```

The script is idempotent — re-running it is safe. Existing files are backed up
to `<name>.bak.<timestamp>` before being overwritten.

## What the installer does

1. Preflight checks (`omarchy`, `sudo`).
2. Ensures the JetBrainsMono Nerd Font.
3. Ensures core packages (`foot ghostty fastfetch starship`).
4. Installs and applies the Dracula theme (`omarchy theme install` / `omarchy theme set`).
5. Copies the bundled `rob.*` plugins and clones the third-party plugins
   (`ai-usagebar`, `vitals`) with `omarchy plugin add`.
6. Copies all configs into `~/.config/`.
7. Copies wallpapers and sets the active background.
8. Installs the `my-split` SDDM theme to `/usr/share/sddm/themes/` and points
   SDDM at it.
9. Restarts the shell and reloads Hyprland.

## Repository layout

```
install.sh                  # the installer
config/                     # dotfiles, mirrored into ~/.config/
  hypr/                     # hyprland.lua, monitors.lua, looknfeel.lua
  omarchy/                  # shell.json, defaults/agent
  foot/ ghostty/            # terminal configs (font size 11)
  fastfetch/ starship.toml
plugins/                    # bundled rob.* plugins
backgrounds/dracula/        # wallpapers
sddm/                       # my-split theme + SDDM config snippet
```

## Notes

- The Dracula theme and third-party plugins are installed from their upstream
  git repos, not vendored, so they stay updateable.
- `config/hypr/monitors.lua` auto-detects the primary monitor and uses its
  preferred mode (`GDK_SCALE` is pinned to `1`). Adjust it for HiDPI/refresh
  needs on other hardware.
- The SDDM wallpaper and lock-screen avatar are your personal assets and are
  bundled in this (Public) repo.
