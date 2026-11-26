# Changelog

## 2.0.0 (November 2026)

A full clean-up of the repository.

### Repository
- New layout: `macos/` and `windows/`, with short folder names without spaces.
- New README with a tool overview, quick start and safety notes.
- One license and one security policy for the whole repository (the IntuneWinAppUtil GUI README wrongly said MIT).
- Automatic checks on every push: ShellCheck for Bash, PSScriptAnalyzer for PowerShell.
- The compiled `IntuneWinAppUtilGUI.exe` is no longer stored in the code. It is built automatically from the script and attached to each GitHub Release.
- Line endings fixed per platform (`.gitattributes`); personal input and output files ignored (`.gitignore`).

### Microsoft Defender Removal (macOS)
- **Fixed:** the script began with an empty line, so the `#!/bin/bash` line was ignored.
- **Fixed:** it deleted the whole `/Library/Application Support/Microsoft` folder and every `com.microsoft.*` preference, which broke Office, Teams, Edge and AutoUpdate. It now removes Defender files only.
- **Fixed:** Microsoft's own uninstaller now runs first. Before, its files were deleted before it could run.
- Removed `systemextensionsctl uninstall`, which only works with System Integrity Protection turned off.
- New: root check, `--dry-run`, `--yes`, `--no-restart`, MDM profile warning, log file at `/var/log/uninstall_defender.log`.

### AnyDesk Removal (macOS)
- Background services are now stopped properly before their files are removed.
- Cleans the settings of every user account, so it works when run by an MDM as root.
- Forgets the installer receipts.
- New: root check, `--dry-run`, `--yes`.

### macOS Cache Cleaner
- Shows the cache size before and after, and the largest caches.
- Refuses to run with `sudo`, which would have cleaned root's caches instead of yours.
- New: `--dry-run`, `--yes`, `--no-restart`; uses a normal macOS restart.

### IntuneWinAppUtil GUI (Windows)
- **Fixed:** folders with spaces broke the conversion, because the paths were not quoted.
- **Fixed:** the script no longer asks for administrator rights just to open its window.
- No more console window during conversion; the Convert button is disabled while it runs; the success message shows the package's location.
- Runs the Microsoft tool in quiet mode (`-q`) so it never waits on a hidden prompt.

### Lenovo Warranty Scanner (Windows)
- Paths are now parameters: `-SerialsFile`, `-OutputFile`, `-DelaySeconds`.
- Installs `Get-LenovoInfo` for the current user without needing administrator rights, and finds it straight away.
- Skips blank lines, `#` comments and duplicate serials; clear messages when the input file is missing.
- Adds a `DaysLeft` column and a short pause between lookups.
- The example serial file is now `serials.example.txt`, so your real list is never committed.

## 1.x (2025)
- First versions of the five scripts.
