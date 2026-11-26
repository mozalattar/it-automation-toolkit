# Microsoft Defender Removal (macOS)

Fully removes **Microsoft Defender for Endpoint** from a Mac. It runs Microsoft's own uninstaller first, then cleans the leftovers it can leave behind. Office, Teams, Edge and Microsoft AutoUpdate are not touched.

## Before you start

- **Managed Macs:** if Defender was deployed by Intune, Jamf or another MDM, remove the app assignment and the Defender configuration profiles in the MDM first, or it will be reinstalled.
- **Tamper protection:** in `block` mode it prevents removal. Set it to `audit` or `disabled` in the Defender portal or the MDM policy before running.

## Usage

```bash
chmod +x uninstall_defender.sh
sudo ./uninstall_defender.sh --dry-run   # preview, changes nothing
sudo ./uninstall_defender.sh             # remove, asks before starting
```

| Option | What it does |
|---|---|
| `--dry-run` | Lists everything that would be removed. Changes nothing. |
| `--yes` | No questions. Use this when deploying through an MDM. |
| `--no-restart` | Never offers a restart at the end. |

Every action is logged to `/var/log/uninstall_defender.log`.

## What it does

1. Runs Microsoft's supported uninstaller (`install_helper … --post-uninstall-hook`).
2. Stops any Defender launch daemons and agents that are still loaded.
3. Removes the Defender app, its support files, logs and preferences.
4. Forgets the Defender installer receipts, so it can be reinstalled cleanly later.
5. Offers a restart to unload Defender's system extensions.

## Run it from Intune

Upload `uninstall_defender.sh` under **Devices → macOS → Shell scripts** and add `--yes --no-restart` at the top of the run command, or edit the defaults at the top of the script. Run as **root**.

Microsoft reference: [Uninstall Defender for Endpoint on Mac](https://learn.microsoft.com/defender-endpoint/mac-resources#uninstalling)

---
Part of [MozlattarScriptMaster](../../README.md) · by Mohammed AlAttar
