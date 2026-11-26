#!/bin/bash
#
# uninstall_anydesk.sh
# Completely removes AnyDesk from a Mac: app, background services and the
# settings of every user account.
#
# Usage:
#   sudo ./uninstall_anydesk.sh [--dry-run] [--yes]
#
#   --dry-run  Show what would be removed, change nothing.
#   --yes      Don't ask for confirmation (for MDM / scripted runs).
#
# Works when run by an MDM as root: it cleans every user in /Users, not just
# the account that runs it.
#
# Author: Mohammed AlAttar · https://github.com/mozalattar

set -uo pipefail

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg (see --help)"; exit 2 ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $*"; }
run() { if [ "$DRY_RUN" -eq 1 ]; then log "DRY RUN: $*"; else "$@" 2>/dev/null || true; fi; }
remove_path() { if [ -e "$1" ] || [ -L "$1" ]; then log "Removing $1"; run rm -rf "$1"; fi; }

if [ "$(uname -s)" != "Darwin" ]; then echo "This script is for macOS only."; exit 1; fi
if [ "$EUID" -ne 0 ]; then echo "Please run with sudo: sudo $0 $*"; exit 1; fi

if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    read -r -p "Remove AnyDesk completely from this Mac? (y/n): " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
fi

log "Stopping AnyDesk..."
for plist in /Library/LaunchDaemons/com.philandro.anydesk*.plist /Library/LaunchAgents/com.philandro.anydesk*.plist; do
    [ -e "$plist" ] || continue
    if [[ "$plist" == /Library/LaunchDaemons/* ]]; then
        run launchctl bootout system "$plist"
    else
        # Agents run inside each logged-in user's session
        for uid in $(ps -axo uid=,comm= | awk '/loginwindow/ {print $1}' | sort -u); do
            run launchctl bootout "gui/$uid" "$plist"
        done
    fi
    remove_path "$plist"
done
run pkill -f "AnyDesk"
sleep 2

log "Removing the application and system files..."
remove_path "/Applications/AnyDesk.app"
remove_path "/Library/PrivilegedHelperTools/com.philandro.anydesk.Helper"
remove_path "/Library/Preferences/com.philandro.anydesk.plist"
remove_path "/Library/Application Support/AnyDesk"
for f in /Library/Logs/DiagnosticReports/AnyDesk*; do remove_path "$f"; done

log "Removing settings for every user..."
for home in /Users/*; do
    [ -d "$home/Library" ] || continue
    remove_path "$home/Library/Preferences/com.philandro.anydesk.plist"
    remove_path "$home/Library/Application Support/AnyDesk"
    remove_path "$home/Library/Caches/com.philandro.anydesk"
    remove_path "$home/Library/Saved Application State/com.philandro.anydesk.savedState"
    remove_path "$home/Library/Logs/AnyDesk"
    remove_path "$home/Library/HTTPStorages/com.philandro.anydesk"
done

for pkg in $(pkgutil --pkgs 2>/dev/null | grep -i 'philandro'); do
    log "Forgetting package receipt $pkg"
    run pkgutil --forget "$pkg"
done

if [ "$DRY_RUN" -eq 1 ]; then
    log "Dry run finished. Nothing was changed."
else
    log "AnyDesk has been removed."
fi
