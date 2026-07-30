#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Flight Studio — Windows cleanup script
#
# Removes every directory and file this application creates on the C drive
# (user-preference stores, cache, SQLite databases, log files).
#
# Run from Git Bash / MSYS2 / WSL on Windows:
#
#     bash clean-c-drive.sh
#
# The script is safe to re-run — it only deletes things it confirms exist.
# It does NOT touch the project source tree, Flutter SDK, or any other app.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

APP_NAME="flight_studio"

# Colours for nicer output (skip if stdout is not a terminal).
if [ -t 1 ]; then
    BOLD='\033[1m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    BOLD='' GREEN='' YELLOW='' RED='' DIM='' RESET=''
fi

echo -e "${BOLD}Flight Studio — C drive cleanup${RESET}"
echo -e "${DIM}Removing all data created by '$APP_NAME' for the current user.${RESET}"
echo ""

removed=0
skipped=0

# ── helper ──────────────────────────────────────────────────────────────────

# Removes a directory if it exists, printing a coloured status line.
#   $1 = human-readable label
#   $2 = full path
remove_dir() {
    local label="$1"
    local dir="$2"

    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}✓ removed${RESET}  $label"
        echo -e "           ${DIM}$dir${RESET}"
        rm -rf "$dir"
        ((removed++)) || true
    else
        echo -e "  ${DIM}· not found  $label${RESET}"
        ((skipped++)) || true
    fi
}

# Removes a single file if it exists.
remove_file() {
    local label="$1"
    local file="$2"

    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓ removed${RESET}  $label"
        echo -e "           ${DIM}$file${RESET}"
        rm -f "$file"
        ((removed++)) || true
    else
        echo -e "  ${DIM}· not found  $label${RESET}"
        ((skipped++)) || true
    fi
}

# ── locate Windows user-profile directories ─────────────────────────────────

# Windows environment variables are inherited by Git Bash / MSYS2.
# Fall back to the standard Cygwin-style path if they are missing.
APPDATA_DIR="${APPDATA:-$USERPROFILE/AppData/Roaming}"
LOCALAPPDATA_DIR="${LOCALAPPDATA:-$USERPROFILE/AppData/Local}"

# Normalise Windows-style back-slash paths to forward-slash for bash.
APPDATA_DIR="${APPDATA_DIR//\\//}"
LOCALAPPDATA_DIR="${LOCALAPPDATA_DIR//\\//}"

echo -e "${BOLD}Roaming data${RESET}  ${DIM}($APPDATA_DIR)${RESET}"
remove_dir "Roaming app data"          "$APPDATA_DIR/$APP_NAME"
remove_dir "Roaming (com.* prefix)"    "$APPDATA_DIR/com.$APP_NAME.$APP_NAME"
echo ""

echo -e "${BOLD}Local data${RESET}  ${DIM}($LOCALAPPDATA_DIR)${RESET}"
remove_dir "Local app data"            "$LOCALAPPDATA_DIR/$APP_NAME"
remove_dir "Local cache"               "$LOCALAPPDATA_DIR/$APP_NAME/cache"
echo ""

# shared_preferences stores a JSON file directly inside the roaming dir.
echo -e "${BOLD}Preference files${RESET}"
remove_file "shared_preferences.json"  "$APPDATA_DIR/$APP_NAME/shared_preferences.json"
echo ""

# ── summary ─────────────────────────────────────────────────────────────────

echo -e "${BOLD}Done.${RESET}  ${GREEN}$removed${RESET} item(s) removed, ${DIM}$skipped${RESET} not found."
echo ""
echo -e "${YELLOW}Note:${RESET} This script only removes user-data directories."
echo -e "      The project source and build output are not affected."
