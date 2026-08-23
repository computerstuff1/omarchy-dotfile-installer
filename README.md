# Omarchy Dotfile Installer

Reproduces a specific [Omarchy](https://omarchy.org) desktop look with one
command. It installs the theme, font, wallpapers, custom bar/menu/clock/
workspaces plugins, and terminal and app configs.

## What it sets up

| Area | Result |
|------|--------|
| Theme | Dracula |
| Font | JetBrainsMono Nerd Font |
| Icon theme | Yaru-red (applied by the Dracula theme) |
| Wallpaper | "They live Desktop.png" (plus 2 others) |
| Status bar | Custom `rob.bar` layout (menu, workspaces, clock, vitals, AI usage bar, tray) |
| Terminals | foot, ghostty (font size 11) |
| Apps | fastfetch, starship configs |
| Hyprland | monitor (auto-detect), look'n'feel overrides |
avatar.png
## Requirements

- An existing [Omarchy](https://omarchy.org) installation.

## Install
metadata.desktop
```bash
git clone https://github.com/computerstuff1/omarchy-dotfile-installer.git
cd omarchy-dotfile-installer
./install.sh
```

The script is idempotent — re-running it is safe. Existing files are backed up
to `<name>.bak.<timestamp>` before being overwritten.

## What the installer does

1. Preflight checks (`omarchy`).
2. Ensures the JetBrainsMono Nerd Font.
3. Ensures core packages (`foot ghostty fastfetch starship`).
4. Installs and applies the Dracula theme (`omarchy theme install` / `omarchy theme set`).
5. Copies the bundled `rob.*` plugins and clones the third-party plugins
   (`ai-usagebar`, `vitals`) with `omarchy plugin add`.
6. Copies all configs into `~/.config/`.
7. Copies wallpapers and sets the active background.
8. Restarts the shell and reloads Hyprland.

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
```

## Notes
- SDDM/ Lockscreen username is Hard coded Rob in metadata.desktop.
- The Dracula theme and third-party plugins are installed from their upstream
  git repos, not vendored, so they stay updateable.
- `config/hypr/monitors.lua` auto-detects the primary monitor and uses its
  preferred mode (`GDK_SCALE` is pinned to `1`). Adjust it for HiDPI/refresh
  needs on other hardware.
