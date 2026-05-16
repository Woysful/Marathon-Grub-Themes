#!/bin/sh
# Marathon GRUB Theme Installer
# Copyright (C) 2026  @woysful && @saifdemos
# License: GPL v3 — see LICENSE in repo root

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
THEMES_DEST="/usr/share/grub/themes"
GRUB_CONFIG="/etc/default/grub"
GRUB_CMD="grub-mkconfig"
GRUB_OUTPUT="/boot/grub/grub.cfg"

SELECTED_THEME=""
SELECTED_RESOLUTION=""
NO_GRUB_UPDATE=false
ASSUME_YES=false

# ── Color output helpers ──────────────────────────────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

info()  { printf "${GREEN}%s${NC}\n" "$@"; }
warn()  { printf "${YELLOW}WARN: %s${NC}\n" "$@"; }
err()   { printf "${RED}ERROR: %s${NC}\n" "$@"; }

# ── ASCII banner ──────────────────────────────────────────────────────
show_banner() {
    info ""
    info " ██████   ██████                                █████    █████                            "
    info "░░██████ ██████                                ░░███    ░░███                             "
    info " ░███░█████░███   ██████   ████████   ██████   ███████   ░███████    ██████  ████████     "
    info " ░███░░███ ░███  ░░░░░███ ░░███░░███ ░░░░░███ ░░░███░    ░███░░███  ███░░███░░███░░███    "
    info " ░███ ░░░  ░███   ███████  ░███ ░░░   ███████   ░███     ░███ ░███ ░███ ░███ ░███ ░███    "
    info " ░███      ░███  ███░░███  ░███      ███░░███   ░███ ███ ░███ ░███ ░███ ░███ ░███ ░███    "
    info " █████     █████░░████████ █████    ░░████████  ░░█████  ████ █████░░██████  ████ █████   "
    info "░░░░░     ░░░░░  ░░░░░░░░ ░░░░░      ░░░░░░░░    ░░░░░  ░░░░ ░░░░░  ░░░░░░  ░░░░ ░░░░░    "                                                                                       
    info ""
    info "                                      GRUB THEMES"
    info ""
}

# ── Help ──────────────────────────────────────────────────────────────
usage() {
    show_banner
    cat <<EOF
Usage: $0 [options]

Options:
  --theme <name>         Skip theme selection menu
  --resolution <name>    Skip resolution selection menu
  --no-grub-update       Copy theme only, skip grub-mkconfig
  -y                     Skip all prompts (first theme, first resolution)
  --help                 Show this help and exit
EOF
    exit 0
}

# ── Interactive numbered picker ───────────────────────────────────────
# Prints menu to stderr, echoes selected 1-based index to stdout.
# Returns non-zero if input is invalid/empty.
pick_one() {
    prompt="$1"
    shift
    i=1
    for item in "$@"; do
        printf "%d) %s\n" "$i" "$item" >&2
        i=$((i + 1))
    done
    printf "%s " "$prompt" >&2
    read choice
    case "$choice" in
        ''|*[!0-9]*) echo ""; return 1 ;;
        *)
            if [ "$choice" -ge 1 ] && [ "$choice" -le "$#" ]; then
                echo "$choice"
                return 0
            fi
            echo ""; return 1
            ;;
    esac
}

confirm() {
    printf "%s [y/N] " "$*" >&2
    read ans
    case "$ans" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Package manager detection ─────────────────────────────────────────
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman";  PKG_INSTALL="pacman -S --noconfirm"; PKG_NAME="grub"
    elif command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt";     PKG_INSTALL="apt install -y";         PKG_NAME="grub-pc"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf";     PKG_INSTALL="dnf install -y";         PKG_NAME="grub2"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper";  PKG_INSTALL="zypper install -y";      PKG_NAME="grub2"
    else
        return 1
    fi
    return 0
}

# ── GRUB config update ────────────────────────────────────────────────
set_grub_config() {
    theme_path="$1"
    if grep -q "^GRUB_THEME=" "$GRUB_CONFIG" 2>/dev/null; then
        sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$theme_path\"|" "$GRUB_CONFIG"
    elif grep -q "^#GRUB_THEME=" "$GRUB_CONFIG" 2>/dev/null; then
        sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"$theme_path\"|" "$GRUB_CONFIG"
    else
        printf '\n%s\n' "GRUB_THEME=\"$theme_path\"" >> "$GRUB_CONFIG"
    fi
}

# ── Argument parsing ──────────────────────────────────────────────────
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help) usage ;;
        --theme)
            shift; SELECTED_THEME="$1"
            ;;
        --resolution)
            shift; SELECTED_RESOLUTION="$1"
            ;;
        --no-grub-update) NO_GRUB_UPDATE=true ;;
        -y) ASSUME_YES=true ;;
        *) err "Unknown option: $1"; usage ;;
    esac
    shift
done

show_banner

# ── Root check ────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    err "This script must be run as root (use sudo)."
    exit 1
fi

# ── Dependency check ──────────────────────────────────────────────────
if ! command -v "$GRUB_CMD" >/dev/null 2>&1; then
    if detect_package_manager; then
        warn "grub-mkconfig not found. Installing via $PKG_MANAGER..."
        $PKG_INSTALL "$PKG_NAME"
        if ! command -v "$GRUB_CMD" >/dev/null 2>&1; then
            err "grub-mkconfig still not found after install. Aborting."
            exit 1
        fi
        info "grub installed successfully."
    else
        err "grub-mkconfig not found and no known package manager detected."
        err "Install GRUB manually, then re-run this script."
        exit 1
    fi
else
    info "grub-mkconfig found."
fi

# ── Discover themes ───────────────────────────────────────────────────
cd "$SCRIPT_DIR"
set -- Marathon-*/
if [ ! -d "$1" ] || [ "$1" = "Marathon-*/" ]; then
    err "No Marathon-* theme directories found in $SCRIPT_DIR."
    exit 1
fi

# Strip trailing slashes from theme dir names
THEME_NAMES=""
for d in "$@"; do THEME_NAMES="$THEME_NAMES ${d%/}"; done
THEME_NAMES="${THEME_NAMES# }"
set -- $THEME_NAMES

# ── Select theme ──────────────────────────────────────────────────────
if [ -n "$SELECTED_THEME" ]; then
    match=
    for d in "$@"; do
        if [ "$d" = "$SELECTED_THEME" ]; then match=1; break; fi
    done
    if [ -z "$match" ]; then
        err "Theme '$SELECTED_THEME' not found. Available: $*"
        exit 1
    fi
    THEME_DIR="$SELECTED_THEME"
elif $ASSUME_YES; then
    THEME_DIR="$1"
else
    echo ""
    info "Available themes:"
    idx=$(pick_one "Select a theme (1-${#}):" "$@") || { err "Invalid selection."; exit 1; }
    eval "THEME_DIR=\${$idx}"
fi

info "Selected theme: $THEME_DIR"
THEME_NAME="$THEME_DIR"

# ── Discover resolutions ──────────────────────────────────────────────
cd "$SCRIPT_DIR/$THEME_DIR"
set -- theme_*.txt
if [ "$#" -eq 0 ]; then
    err "No theme_*.txt files found in $THEME_DIR."
    exit 1
fi

# Build indexed resolution file list
RES_COUNT=0
for f in "$@"; do
    RES_COUNT=$((RES_COUNT + 1))
    eval "RES_FILE_${RES_COUNT}=\$f"
done

# Strip 'theme_' prefix and '.txt' suffix for display
RES_NAMES=""
i=1
while [ "$i" -le "$RES_COUNT" ]; do
    eval "f=\$RES_FILE_${i}"
    name="${f#theme_}"; name="${name%.txt}"
    RES_NAMES="$RES_NAMES $name"
    i=$((i + 1))
done
RES_NAMES="${RES_NAMES# }"
set -- $RES_NAMES

# ── Select resolution ─────────────────────────────────────────────────
if [ -n "$SELECTED_RESOLUTION" ]; then
    match=
    i=1
    for name in "$@"; do
        if [ "$name" = "$SELECTED_RESOLUTION" ]; then match=$i; break; fi
        i=$((i + 1))
    done
    if [ -z "$match" ]; then
        err "Resolution '$SELECTED_RESOLUTION' not found. Available: $*"
        exit 1
    fi
    RES_IDX=$match
    eval "RES_FILE=\${RES_FILE_${RES_IDX}}"
elif $ASSUME_YES || [ "$RES_COUNT" -eq 1 ]; then
    eval "RES_FILE=\${RES_FILE_1}"
else
    echo ""
    info "Available resolutions:"
    idx=$(pick_one "Select a resolution (1-${#}):" "$@") || { err "Invalid selection."; exit 1; }
    eval "RES_FILE=\${RES_FILE_${idx}}"
fi

RES_NAME="${RES_FILE#theme_}"
RES_NAME="${RES_NAME%.txt}"
info "Selected resolution: $RES_NAME"

# ── Confirmation ─────────────────────────────────────────────────────
echo ""
info "Ready to install:"
info "  Theme:      $THEME_NAME"
info "  Config:     $RES_FILE"
info "  Destination: $THEMES_DEST/$THEME_NAME/"
if ! $NO_GRUB_UPDATE; then
    info "  GRUB update: yes (grub-mkconfig)"
fi
echo ""

if ! $ASSUME_YES; then
    confirm "Proceed with installation?" || { info "Aborted."; exit 0; }
fi

# ── Copy theme ────────────────────────────────────────────────────────
if [ -d "$THEMES_DEST/$THEME_NAME" ]; then
    warn "Theme already exists at $THEMES_DEST/$THEME_NAME"
    if ! $ASSUME_YES; then
        confirm "Overwrite?" || { info "Aborted."; exit 0; }
    fi
    rm -rf "$THEMES_DEST/$THEME_NAME"
fi

info "Copying theme files..."
cp -r "$SCRIPT_DIR/$THEME_DIR" "$THEMES_DEST/$THEME_NAME"
info "Theme copied to $THEMES_DEST/$THEME_NAME"

# ── Update GRUB config ────────────────────────────────────────────────
THEME_RES_PATH="$THEMES_DEST/$THEME_NAME/$RES_FILE"
info "Updating $GRUB_CONFIG..."
set_grub_config "$THEME_RES_PATH"
info "GRUB_THEME set to $THEME_RES_PATH"

# ── Run grub-mkconfig ──────────────────────────────────────────────────
if $NO_GRUB_UPDATE; then
    info "Skipping grub-mkconfig (--no-grub-update)."
    info "Run 'sudo grub-mkconfig -o $GRUB_OUTPUT' manually to apply."
else
    info "Running grub-mkconfig..."
    $GRUB_CMD -o "$GRUB_OUTPUT"
    info "GRUB configuration updated."
fi

echo ""
info "Installation complete!"
info "Reboot to see your new theme."
