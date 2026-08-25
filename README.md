# Omarchy Dotfile Installer

Reproduces a specific [Omarchy](https://omarchy.org) desktop look with one
command. It installs the theme, font, wallpapers, custom bar/menu/clock/
workspaces plugins, and terminal and app configs.

## What it sets up

| Area | Result |
|------|--------|
| Theme | Dracula (accent + popup/menu/notification borders tuned to the window border) |
| Font | JetBrainsMono Nerd Font |
| Icon theme | Yaru-red (applied by the Dracula theme) |
| Wallpaper | "They live Desktop.png" (plus 2 others) |
| Status bar | Custom `rob.bar` layout (menu, workspaces, clock, vitals, system updates, tray) |
| Terminals | foot, ghostty, alacritty, kitty (font size 11) |
| Apps | fastfetch, starship configs |
| Hyprland | monitor (auto-detect), look'n'feel overrides |

<img width="171" height="79" alt="screenshot-2026-08-24_19-16-49" src="https://github.com/user-attachments/assets/49bd76a8-68fb-4543-996b-fac3b1ae3fc8" />
<img width="265" height="65" alt="screenshot-2026-08-24_13-25-49" src="https://github.com/user-attachments/assets/e99992cc-5858-4e82-832c-390c844a595e" />
<img width="264" height="80" alt="screenshot-2026-08-24_13-26-32" src="https://github.com/user-attachments/assets/ae0742aa-074e-4fe7-8012-f4d36ff5275e" />
<img width="1920" height="1080" alt="screenshot-2026-08-24_20-00-51" src="https://github.com/user-attachments/assets/318942bc-74d7-4ee5-98ae-e3582d5cf52b" />
<img width="1006" height="708" alt="screenshot-2026-08-25_00-56-05" src="https://github.com/user-attachments/assets/d7d0e63d-7c9a-4c38-8c61-6fcc1564aa40" />
<img width="329" height="383" alt="screenshot-2026-08-24_19-15-53" src="https://github.com/user-attachments/assets/0ff0c0f4-c630-49dc-8734-4be40336fa82" />

## Requirements

- An existing [Omarchy](https://omarchy.org) installation.

## Install

```bash
git clone https://github.com/computerstuff1/omarchy-dotfile-installer.git
cd omarchy-dotfile-installer
./install.sh
```

The script is idempotent — re-running it is safe. Config files are backed up
to `<name>.bak.<timestamp>` before being overwritten; bundled plugins are
overwritten in place (stale `*.bak.*` plugin dirs from older runs are pruned
first so they can't shadow the live plugins).

## Run order on a fresh install

Run these in this order after removing the preinstalled applications:

1. **omarchy-pkg-installer** — installs the apps
   ```bash
   git clone https://github.com/computerstuff1/omarchy-pkg-installer.git
   cd omarchy-pkg-installer
   ./install.sh
   ```
2. **this installer** — applies the theme, font, and all configs
   ```bash
   git clone https://github.com/computerstuff1/omarchy-dotfile-installer.git
   cd omarchy-dotfile-installer
   ./install.sh
   ```

Installing the apps first and applying configs last means the font
(JetBrainsMono) and the theme are in place before the shell restarts, so the
new apps pick them up immediately — e.g. ghostty reads its config and the
dynamic theme file that `omarchy theme set` writes.

## What the installer does

1. Preflight checks (`omarchy`).
2. Ensures the JetBrainsMono Nerd Font.
3. Installs and applies the Dracula theme (`omarchy theme install` / `omarchy theme set`).
   Cosmetic only: no packages are installed; app configs are copied for apps that
   already exist.
   Browsers are excluded from theming: the theme's bundled `firefox/userChrome.css`
   is stripped, and the themed `BrowserThemeColor` policy written by
   `omarchy theme set` for Chromium-family browsers is removed.
4. Copies the bundled `rob.*` plugins (bar, clock, menu, system-updates,
   vitals, workspaces) into `~/.config/omarchy/plugins/`.
5. Copies all configs into `~/.config/`.
6. Copies wallpapers and sets the active background.
7. Restarts the shell and reloads Hyprland.

## Repository layout

```
install.sh                  # the installer
config/                     # dotfiles, mirrored into ~/.config/
  hypr/                     # hyprland.lua, monitors.lua, looknfeel.lua
  omarchy/                  # shell.json, bin/, defaults/agent, branding/about.txt
  foot/ ghostty/ alacritty/ kitty/   # terminal configs (font size 11)
  fastfetch/ starship.toml
plugins/                    # bundled rob.* plugins (bar, clock, menu, system-updates, vitals, workspaces)
backgrounds/dracula/        # wallpapers
```

## Notes
- `config/hypr/monitors.lua` auto-detects the primary monitor and uses its
  preferred mode (`GDK_SCALE` is pinned to `1`). Adjust it for HiDPI/refresh
  needs on other hardware.

## Show fastfetch on every terminal

Add this to `~/.bashrc` to print your system info once per new terminal:

```bash
# Show system info once per terminal (guarded against double-sourcing)
if [[ -z "$FASTFETCH_SHOWN" ]]; then
  export FASTFETCH_SHOWN=1
  fastfetch
fi
```

**Where to put it:** at the bottom of `~/.bashrc` (`nano ~/.bashrc`).

**What it does:**
- `fastfetch` prints the system info banner.
- The `FASTFETCH_SHOWN` guard makes it run exactly **once**, even when
  `~/.bashrc` gets sourced more than once per session (e.g. via
  `~/.bash_profile`). This prevents fastfetch from appearing multiple times.
- It re-arms for every new terminal, so each window shows the info once.

**Avoid:** adding a bare `fastfetch` (or several) to `~/.bashrc`, and never
append to it with `echo "fastfetch" >> ~/.bashrc` — that self-modifying line
grows the file and runs fastfetch again and again on every launch.
