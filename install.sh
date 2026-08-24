#!/usr/bin/env bash
#
# Omarchy dotfile installer
#
# Reproduces a specific Omarchy desktop look: Dracula theme, JetBrainsMono Nerd
# Font, custom bar/menu/clock/workspaces/system-updates/vitals plugins,
# wallpapers, and terminal configs.
#
# Idempotent: safe to re-run. Existing files are backed up before being
# overwritten, and already-installed themes/plugins/packages are skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
BACKGROUNDS_DIR="$SCRIPT_DIR/backgrounds"

# ----------------------------------------------------------------------------
# Cosmetic logging
# ----------------------------------------------------------------------------
C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_CYAN=$'\033[36m'

info() { printf '%s\n' "${C_CYAN}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }
ok()   { printf '%s\n' "${C_GREEN}  \u2713${C_RESET} $*"; }
warn() { printf '%s\n' "${C_YELLOW}  !${C_RESET} $*"; }
fail() { printf '%s\n' "${C_RED}  \u2717${C_RESET} $*" >&2; }
die()  { fail "$*"; exit 1; }

banner() {
  printf '\n%s\n' "${C_BOLD}$*${C_RESET}"
}

# ----------------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------------
FONT_FAMILY="JetBrainsMono Nerd Font"
FONT_PACKAGE="ttf-jetbrains-mono-nerd"

THEME_REPO="https://github.com/catlee/omarchy-dracula-theme.git"
THEME_NAME="dracula"

ACTIVE_WALLPAPER="They live Desktop.png"

# Plugins bundled in this repo (copied verbatim into ~/.config/omarchy/plugins).
BUNDLED_PLUGINS=(rob.bar rob.clock rob.menu rob.system-updates rob.vitals rob.workspaces)

# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------
require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Required command '$1' not found. $2"
  fi
}

# Copy a file into place, backing up an existing target that differs.
install_file() {
  local src="$1" dst="$2"
  if [[ ! -f "$src" ]]; then
    warn "skipping missing source: $src"
    return 0
  fi
  if [[ -e "$dst" ]] && ! cmp -s "$src" "$dst"; then
    local bak="$dst.bak.$(date +%s)"
    mv "$dst" "$bak"
    warn "backed up existing file: $dst -> $(basename "$bak")"
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  ok "installed $(basename "$dst")"
}

# Copy a directory's contents into place, backing up an existing target dir.
install_dir() {
  local src="$1" dst="$2"
  if [[ ! -d "$src" ]]; then
    warn "skipping missing source dir: $src"
    return 0
  fi
  if [[ -e "$dst" ]]; then
    local bak="$dst.bak.$(date +%s)"
    mv "$dst" "$bak"
    warn "backed up existing dir: $dst -> $(basename "$bak")"
  fi
  mkdir -p "$dst"
  cp -r "$src"/. "$dst"/
  ok "installed $(basename "$dst")/"
}

# ----------------------------------------------------------------------------
# Steps
# ----------------------------------------------------------------------------
step_preflight() {
  banner "Preflight"
  require omarchy "This installer targets Omarchy (https://omarchy.org)."
  info "Omarchy $(omarchy version)"
  ok "preflight passed"
}

step_font() {
  banner "Font"
  if fc-list : family | grep -qiF "$FONT_FAMILY"; then
    ok "font already installed: $FONT_FAMILY"
  else
    info "installing font: $FONT_FAMILY"
    omarchy install font "$FONT_FAMILY" "$FONT_PACKAGE" "$FONT_FAMILY"
    ok "font installed"
  fi
}

step_theme() {
  banner "Theme"
  if [[ -d "$HOME/.config/omarchy/themes/$THEME_NAME" ]]; then
    ok "theme already installed: $THEME_NAME"
  else
    info "installing theme from $THEME_REPO"
    omarchy theme install "$THEME_REPO"
    ok "theme installed"
  fi

  # Firefox: strip the bundled userChrome.css from the installed theme so the
  # browser UI is never re-skinned. The theme is re-applied below from this
  # cleaned copy.
  rm -rf "$HOME/.config/omarchy/themes/$THEME_NAME/firefox"

  info "applying theme: $THEME_NAME"
  omarchy theme set "$THEME_NAME"
  ok "theme applied"

  # Chromium-family browsers (Chromium, Chrome, Edge, Brave): `omarchy theme
  # set` always writes a themed BrowserThemeColor policy via
  # omarchy-theme-set-browser. Remove it so the browser keeps its default look.
  info "excluding web browsers from theming"
  for f in \
    /etc/chromium/policies/managed/color.json \
    /etc/opt/chrome/policies/managed/color.json \
    /etc/opt/edge/policies/managed/color.json \
    /etc/brave/policies/managed/color.json
  do
    if [[ -e "$f" ]]; then
      if sudo rm -f "$f" 2>/dev/null; then
        ok "removed browser theme policy: $f"
      else
        warn "cannot remove $f; remove it manually"
      fi
    fi
  done
}

step_plugins() {
  banner "Plugins"

  info "installing bundled plugins"
  for plugin in "${BUNDLED_PLUGINS[@]}"; do
    install_dir "$PLUGINS_DIR/$plugin" "$HOME/.config/omarchy/plugins/$plugin"
  done
}

step_configs() {
  banner "Config files"

  info "installing Hyprland config"
  for f in "$CONFIG_DIR/hypr/"*; do
    [[ -f "$f" ]] || continue
    install_file "$f" "$HOME/.config/hypr/$(basename "$f")"
  done

  info "installing Omarchy shell config"
  install_file "$CONFIG_DIR/omarchy/shell.json" "$HOME/.config/omarchy/shell.json"
  install_file "$CONFIG_DIR/omarchy/bin/system-update-count" "$HOME/.config/omarchy/bin/system-update-count"
  install_file "$CONFIG_DIR/omarchy/defaults/agent" "$HOME/.config/omarchy/defaults/agent"
  install_file "$CONFIG_DIR/omarchy/branding/about.txt" "$HOME/.config/omarchy/branding/about.txt"

  info "installing terminal configs"
  install_file "$CONFIG_DIR/foot/foot.ini"           "$HOME/.config/foot/foot.ini"
  install_file "$CONFIG_DIR/ghostty/config"          "$HOME/.config/ghostty/config"

  info "installing app configs"
  install_file "$CONFIG_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  install_file "$CONFIG_DIR/starship.toml"          "$HOME/.config/starship.toml"
}

step_backgrounds() {
  banner "Wallpapers"
  info "installing wallpapers"
  for img in "$BACKGROUNDS_DIR/dracula/"*.png; do
    [[ -f "$img" ]] || continue
    install_file "$img" "$HOME/.config/omarchy/backgrounds/$THEME_NAME/$(basename "$img")"
  done

  local target="$HOME/.config/omarchy/backgrounds/$THEME_NAME/$ACTIVE_WALLPAPER"
  info "setting active wallpaper: $ACTIVE_WALLPAPER"
  omarchy theme bg set "$target"
  ok "wallpaper set"
}

step_apply() {
  banner "Apply"

  if command -v omarchy >/dev/null 2>&1; then
    info "restarting shell"
    omarchy restart shell || warn "omarchy restart shell failed"
  fi

  if command -v hyprctl >/dev/null 2>&1; then
    info "reloading Hyprland"
    hyprctl reload || warn "hyprctl reload failed"
  fi

  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null 2>&1 || true
  fi

  ok "done"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat <<'HELP'
Usage: ./install.sh

Reproduces the Omarchy desktop look described in README.md.

Options:
  -h, --help   Show this help and exit.

The script is idempotent. Existing files are backed up before being
overwritten. Run from a terminal.
HELP
    exit 0
  fi

  printf '%s\n' "${C_BOLD}Omarchy dotfile installer${C_RESET}"
  printf 'Repo dir: %s\n\n' "$SCRIPT_DIR"

  step_preflight
  step_font
  step_theme
  step_plugins
  step_configs
  step_backgrounds
  step_apply

  printf '\n%s\n' "${C_GREEN}${C_BOLD}Install complete.${C_RESET}"
}

main "$@"
