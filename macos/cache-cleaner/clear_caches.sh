#!/bin/bash
#
# clear_caches.sh
# Clears the current user's app caches (~/Library/Caches) to free disk space
# and fix problems caused by corrupt caches. Apps rebuild these files
# automatically. Shows the space freed.
#
# Usage:
#   ./clear_caches.sh [--dry-run] [--yes] [--no-restart]
#
#   --dry-run     Show the cache size and what would be deleted, change nothing.
#   --yes         Don't ask for confirmation.
#   --no-restart  Never offer a restart at the end.
#
# Run it as your normal user (no sudo needed). Quit open apps first for the
# best result; files that are in use are skipped safely.
#
# Author: Mohammed AlAttar · https://github.com/mozalattar

set -uo pipefail

DRY_RUN=0
ASSUME_YES=0
NO_RESTART=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=1 ;;
        --yes|-y)     ASSUME_YES=1 ;;
        --no-restart) NO_RESTART=1 ;;
        -h|--help)    sed -n '2,17p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg (see --help)"; exit 2 ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then echo "This script is for macOS only."; exit 1; fi
if [ "$EUID" -eq 0 ]; then
    echo "Run this as your normal user, not with sudo, so it cleans your own caches."; exit 1
fi

CACHE_DIR="$HOME/Library/Caches"
if [ ! -d "$CACHE_DIR" ]; then
    echo "No cache folder found at $CACHE_DIR. Nothing to do."; exit 0
fi

size_of() { du -sh "$1" 2>/dev/null | awk '{print $1}'; }

BEFORE=$(size_of "$CACHE_DIR")
echo "Cache folder: $CACHE_DIR"
echo "Current size: $BEFORE"
echo
echo "Largest caches:"
du -sh "$CACHE_DIR"/* 2>/dev/null | sort -rh | head -10 | sed 's/^/  /'
echo

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run: nothing was deleted."; exit 0
fi

if [ "$ASSUME_YES" -eq 0 ]; then
    echo "Tip: quit open apps (especially browsers) before continuing."
    read -r -p "Delete everything inside $CACHE_DIR? (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
fi

# Delete the contents, never the folder itself. Locked files are skipped.
find "$CACHE_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

AFTER=$(size_of "$CACHE_DIR")
echo "Done. Cache size: $BEFORE → $AFTER"

if [ "$NO_RESTART" -eq 1 ] || [ "$ASSUME_YES" -eq 1 ]; then exit 0; fi
read -r -p "Restart now so every app starts with fresh caches? (y/n): " restart
if [[ "$restart" =~ ^[Yy]$ ]]; then
    osascript -e 'tell application "System Events" to restart' 2>/dev/null || sudo shutdown -r now
else
    echo "Restart skipped."
fi
