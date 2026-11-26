# AnyDesk Removal (macOS)

Completely removes **AnyDesk** from a Mac: the app, its background services and helper, and the AnyDesk settings of **every user account** on the machine.

## Usage

```bash
chmod +x uninstall_anydesk.sh
sudo ./uninstall_anydesk.sh --dry-run   # preview, changes nothing
sudo ./uninstall_anydesk.sh             # remove, asks before starting
```

| Option | What it does |
|---|---|
| `--dry-run` | Lists everything that would be removed. Changes nothing. |
| `--yes` | No questions. Use this when deploying through an MDM. |

## What it removes

- Running AnyDesk processes, plus its launch daemons and agents (stopped first, then deleted)
- `/Applications/AnyDesk.app` and the privileged helper tool
- System-wide preferences, support files and crash reports
- For every user in `/Users`: preferences, Application Support, caches, saved state and logs
- The AnyDesk installer receipts

## Run it from an MDM

The script cleans every user's folder when run as root, so it works as an Intune or Jamf shell script. Run it as **root** with `--yes`.

---
Part of [MozlattarScriptMaster](../../README.md) · by Mohammed AlAttar
