#!/bin/bash
#
# uninstall_defender.sh
# Fully removes Microsoft Defender for Endpoint from a Mac.
#
# Order of operations:
#   1. Run Microsoft's own uninstaller (the supported method).
#   2. Remove Defender-only leftovers. Other Microsoft apps (Office, Teams,
#      Edge, AutoUpdate) are never touched.
#
# Usage:
#   sudo ./uninstall_defender.sh [--dry-run] [--yes] [--no-restart]
#
#   --dry-run     Show what would be removed, change nothing.
#   --yes         Don't ask for confirmation (for MDM / scripted runs).
#   --no-restart  Never offer a restart at the end.
#
# Notes:
#   - If Defender was deployed by an MDM (Intune, Jamf...), remove the app
#     assignment and the Defender configuration profiles in the MDM first,
#     or the MDM will simply reinstall it.
#   - Tamper protection in "block" mode stops removal. Set it to "audit" or
#     "disabled" in the Defender portal or MDM policy before running.
#
# Author: Mohammed AlAttar · https://github.com/mozalattar

set -uo pipefail

DRY_RUN=0
ASSUME_YES=0
NO_RESTART=0
LOG_FILE="/var/log/uninstall_defender.log"

for arg in "$@"; do
    case "$arg" in
        --dry-run)    DRY_RUN=1 ;;
        --yes|-y)     ASSUME_YES=1 ;;
        --no-restart) NO_RESTART=1 ;;
        -h|--help)    sed -n '2,24p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg (see --help)"; exit 2 ;;
    esac
done

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE" 2>/dev/null || echo "$*"; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log "DRY RUN: $*"
    else
        "$@" >>"$LOG_FILE" 2>&1 || log "  (not needed or failed: $*)"
    fi
}

remove_path() {
    local p="$1"
    if [ -e "$p" ] || [ -L "$p" ]; then
        log "Removing $p"
        run rm -rf "$p"
    fi
}

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for macOS only."; exit 1
fi
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo $0 $*"; exit 1
fi

APP="/Applications/Microsoft Defender.app"
SUPPORT="/Library/Application Support/Microsoft/Defender"
HELPER="$SUPPORT/uninstall/install_helper"
UNINSTALLER="$SUPPORT/uninstall/uninstall"

if [ ! -d "$APP" ] && [ ! -d "$SUPPORT" ]; then
    log "Microsoft Defender is not installed. Nothing to do."
    exit 0
fi

if profiles list -all 2>/dev/null | grep -qi "com.microsoft.wdav"; then
    log "WARNING: Defender configuration profiles from an MDM are installed."
    log "         Remove them in your MDM too, or Defender may be reinstalled."
fi

if [ "$ASSUME_YES" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    read -r -p "Remove Microsoft Defender for Endpoint from this Mac? (y/n): " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
fi

log "=== Microsoft Defender removal started ==="

# 1. Microsoft's supported uninstaller (must run before its files are deleted)
if [ -x "$HELPER" ] && [ -e "$UNINSTALLER" ]; then
    log "Running Microsoft's uninstaller..."
    run "$HELPER" execute --path "$UNINSTALLER" --args --post-uninstall-hook
else
    log "Microsoft's uninstaller was not found; removing files manually."
fi

# 2. Stop any Defender launch jobs that are still loaded
for plist in /Library/LaunchDaemons/com.microsoft.wdav*.plist /Library/LaunchDaemons/com.microsoft.fresno*.plist /Library/LaunchAgents/com.microsoft.wdav*.plist; do
    [ -e "$plist" ] || continue
    log "Unloading $plist"
    run launchctl bootout system "$plist"
    remove_path "$plist"
done
run pkill -f "Microsoft Defender"
run pkill -f "wdavdaemon"

# 3. Defender-only leftovers
remove_path "$APP"
remove_path "$SUPPORT"
remove_path "/Library/Application Support/Microsoft/sense"
remove_path "/Library/Logs/Microsoft/mdatp"
remove_path "/Library/Logs/Microsoft/Defender"
for p in /Library/Preferences/com.microsoft.wdav* "/Library/Managed Preferences/com.microsoft.wdav"*; do
    remove_path "$p"
done

# 4. Forget the installer receipts so a clean reinstall is possible later
for pkg in $(pkgutil --pkgs 2>/dev/null | grep -Ei '^com\.microsoft\.(wdav|dlp)'); do
    log "Forgetting package receipt $pkg"
    run pkgutil --forget "$pkg"
done

log "=== Microsoft Defender removal finished ==="
log "Log file: $LOG_FILE"

if [ "$DRY_RUN" -eq 1 ] || [ "$NO_RESTART" -eq 1 ] || [ "$ASSUME_YES" -eq 1 ]; then
    log "Restart the Mac when convenient to finish unloading the system extensions."
    exit 0
fi

read -r -p "A restart is recommended to unload Defender's system extensions. Restart now? (y/n): " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
    shutdown -r now
else
    echo "OK. Please restart later to complete the cleanup."
fi
