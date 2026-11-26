# IT Automation Toolkit

**Practical IT automation scripts for macOS and Windows: clean app removal, Intune packaging and asset audits.**

[![Lint](https://github.com/mozalattar/it-automation-toolkit/actions/workflows/lint.yml/badge.svg)](https://github.com/mozalattar/it-automation-toolkit/actions/workflows/lint.yml) [![Release](https://github.com/mozalattar/it-automation-toolkit/actions/workflows/release.yml/badge.svg)](https://github.com/mozalattar/it-automation-toolkit/releases/latest)

**Platforms:** macOS · Windows  |  **Languages:** Bash · PowerShell  |  **Latest release:** [v2.0.0](https://github.com/mozalattar/it-automation-toolkit/releases/latest)

Scripts written and used in real enterprise environments (Microsoft Intune, macOS fleets, IT audits). Every script explains what it will do before it does it, and the destructive ones support a `--dry-run` mode.

---

## Tools

| Tool | Platform | What it does |
|---|---|---|
| [**IntuneWinAppUtil GUI**](windows/intunewin-gui) | Windows | A drag-and-drop window for Microsoft's Win32 Content Prep Tool. Builds `.intunewin` packages without typing commands. |
| [**Lenovo Warranty Scanner**](windows/lenovo-warranty) | Windows | Checks warranty status, model, purchase year and age for hundreds of Lenovo serials and exports a CSV for asset audits. |
| [**Microsoft Defender Removal**](macos/defender-removal) | macOS | Removes Microsoft Defender for Endpoint with Microsoft's own uninstaller first, then cleans the leftovers. Other Microsoft apps are untouched. |
| [**AnyDesk Removal**](macos/anydesk-removal) | macOS | Removes AnyDesk, its background services and the settings of every user. MDM-friendly. |
| [**macOS Cache Cleaner**](macos/cache-cleaner) | macOS | Clears the user's app caches safely and shows how much space was freed. |

## Quick start

**macOS**

```bash
git clone https://github.com/mozalattar/it-automation-toolkit.git
cd it-automation-toolkit/macos/anydesk-removal
chmod +x uninstall_anydesk.sh
sudo ./uninstall_anydesk.sh --dry-run   # preview first
sudo ./uninstall_anydesk.sh             # then run it
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/mozalattar/it-automation-toolkit.git
cd it-automation-toolkit\windows\lenovo-warranty
Copy-Item serials.example.txt serials.txt   # then add your serials
.\Run-WarrantyCheck.ps1
```

Ready-to-run downloads (including the compiled `IntuneWinAppUtilGUI.exe`) are on the [Releases](https://github.com/mozalattar/it-automation-toolkit/releases) page.

## Using them safely

- **Preview first.** The macOS scripts support `--dry-run`, which lists everything they would remove and changes nothing.
- **Test on one machine** before deploying through an MDM.
- **MDM deployments:** the removal scripts accept `--yes` (no prompts) and clean every user account when run as root, so they work as Intune or Jamf scripts.
- **Managed software:** if an MDM installed the app, remove its assignment and profiles in the MDM first, or the MDM will reinstall it.

## Repository layout

```
it-automation-toolkit/
├── macos/
│   ├── anydesk-removal/      uninstall_anydesk.sh
│   ├── cache-cleaner/        clear_caches.sh
│   └── defender-removal/     uninstall_defender.sh
├── windows/
│   ├── intunewin-gui/        IntuneWinAppUtilGUI.ps1
│   └── lenovo-warranty/      Run-WarrantyCheck.ps1
└── .github/workflows/        lint (ShellCheck, PSScriptAnalyzer) and release builds
```

Every push is checked automatically with **ShellCheck** and **PSScriptAnalyzer**.

## About the author

**Mohammed AlAttar** is an IT manager and systems engineer with 19+ years across fintech, media and enterprise IT in the UAE and abroad. He specialises in endpoint management (Microsoft Intune, macOS), Microsoft 365 and Azure, security operations and automation.

Certifications: CISM · PMP · ITIL 4 · AWS Solutions Architect – Associate · CompTIA Security+ · Microsoft 365 Endpoint Administrator · Azure Administrator · Apple Certified Support Professional · Google IT Support.
Education: Master's in Computer Security Engineering & Artificial Intelligence.

- Website: [mohammedalattarai.com](https://mohammedalattarai.com)
- LinkedIn: [Mohammed AlAttar](https://www.linkedin.com/in/mohammed-z-alattar/)
- Email: [mozalattar@gmail.com](mailto:mozalattar@gmail.com)

## Feedback and security

Found a bug or have an idea? [Open an issue](https://github.com/mozalattar/it-automation-toolkit/issues). For security problems, see [SECURITY.md](SECURITY.md).

## License

Free for personal and internal use; commercial use, redistribution and modified versions need written permission. See [LICENSE](LICENSE).

These scripts are provided as is, without warranty. They are not affiliated with or endorsed by Microsoft, Lenovo, AnyDesk Software GmbH or Apple.
