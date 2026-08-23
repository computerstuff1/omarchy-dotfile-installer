#!/usr/bin/env bash
#
# Omarchy dotfile installer
#
# Reproduces a specific Omarchy desktop look: Dracula theme, JetBrainsMono Nerd
# Font, custom bar/menu/clock/workspaces/lock plugins, wallpapers, terminal
# configs, and a custom SDDM login screen.
#
# Idempotent: safe to re-run. Existing files are backed up before being
# overwritten, and already-installed themes/plugins/packages are skipped.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
BACKGROUNDS_DIR="$SCRIPT_DIR/backgrounds"
SDDM_DIR="$SCRIPT_DIR/sddm"

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
BUNDLED_PLUGINS=(rob.bar rob.clock rob.lock rob.menu rob.workspaces)

# Third-party plugins installed from git.
#   "<plugin-id>" "<git-url>"
THIRD_PARTY_PLUGINS=(
  "akitaonrails.ai-usagebar|https://github.com/akitaonrails/ai-usagebar.git"
  "io.github.woogy7.vitals|https://github.com/Woogy7/omarchy-vitals.git"
)

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
  require sudo "sudo is required to install the SDDM login theme."
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

step_packages() {
  banner "Packages"
  # Core apps whose dotfiles ship in this repo. `omarchy pkg add` no-ops for
  # packages that are already installed.
  omarchy pkg add foot ghostty fastfetch starship btop git
  ok "core packages present"
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
  info "applying theme: $THEME_NAME"
  omarchy theme set "$THEME_NAME"
  ok "theme applied"
}

step_plugins() {
  banner "Plugins"

  info "installing bundled plugins"
  for plugin in "${BUNDLED_PLUGINS[@]}"; do
    install_dir "$PLUGINS_DIR/$plugin" "$HOME/.config/omarchy/plugins/$plugin"
  done

  info "installing third-party plugins"
  for entry in "${THIRD_PARTY_PLUGINS[@]}"; do
    local id="${entry%%|*}" url="${entry##*|}"
    if [[ -d "$HOME/.config/omarchy/plugins/$id" ]]; then
      ok "plugin already installed: $id"
    else
      info "cloning plugin: $id"
      omarchy plugin add "$url" --yes
      ok "plugin installed: $id"
    fi
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
  install_file "$CONFIG_DIR/omarchy/defaults/agent" "$HOME/.config/omarchy/defaults/agent"
  install_file "$CONFIG_DIR/omarchy/extensions/omarchy-menu.jsonc" \
    "$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

  info "installing terminal configs"
  install_file "$CONFIG_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  install_file "$CONFIG_DIR/foot/foot.ini"           "$HOME/.config/foot/foot.ini"
  install_file "$CONFIG_DIR/kitty/kitty.conf"        "$HOME/.config/kitty/kitty.conf"
  install_file "$CONFIG_DIR/ghostty/config"          "$HOME/.config/ghostty/config"

  info "installing app configs"
  install_file "$CONFIG_DIR/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  install_file "$CONFIG_DIR/starship.toml"          "$HOME/.config/starship.toml"
  install_file "$CONFIG_DIR/git/config"             "$HOME/.config/git/config"
  install_file "$CONFIG_DIR/btop/btop.conf"         "$HOME/.config/btop/btop.conf"
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

step_sddm() {
  banner "SDDM login theme"

  local theme_dst="/usr/share/sddm/themes/my-split"
  local conf_src="$SDDM_DIR/omarchy-dotfiles.conf"
  local conf_dst="/etc/sddm.conf.d/99-omarchy-dotfiles.conf"

  info "installing SDDM theme (requires sudo)"
  sudo install -d "$theme_dst"
  for f in "$SDDM_DIR"/Main.qml "$SDDM_DIR"/metadata.desktop \
           "$SDDM_DIR"/theme.conf "$SDDM_DIR"/avatar.png "$SDDM_DIR"/wallpaper.png; do
    [[ -f "$f" ]] || continue
    sudo install -m 0644 "$f" "$theme_dst/"
  done
  ok "SDDM theme copied to $theme_dst"

  info "configuring SDDM to use the theme"
  sudo install -d /etc/sddm.conf.d
  sudo cp "$conf_src" "$conf_dst"
  ok "SDDM configured: $conf_dst"
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
overwritten. Run from a terminal; sudo is prompted once for the SDDM theme.
HELP
    exit 0
  fi

  printf '%s\n' "${C_BOLD}Omarchy dotfile installer${C_RESET}"
  printf 'Repo dir: %s\n\n' "$SCRIPT_DIR"

  step_preflight
  step_font
  step_packages
  step_theme
  step_plugins
  step_configs
  step_backgrounds
  step_sddm
  step_apply

  printf '\n%s\n' "${C_GREEN}${C_BOLD}Install complete.${C_RESET}"
  printf 'Log out and back in (or reboot) to see the SDDM login screen.\n'
}

main "$@"
