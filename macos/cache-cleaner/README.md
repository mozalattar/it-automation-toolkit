# macOS Cache Cleaner

Clears your app caches (`~/Library/Caches`) to free disk space and fix problems caused by corrupt cache files. Apps rebuild what they need automatically. The script shows the cache size before and after.

## Usage

Run it as **your normal user**; no `sudo` is needed.

```bash
chmod +x clear_caches.sh
./clear_caches.sh --dry-run   # shows the size and the biggest caches, deletes nothing
./clear_caches.sh             # asks, then cleans
```

| Option | What it does |
|---|---|
| `--dry-run` | Shows the cache size and the 10 largest caches. Deletes nothing. |
| `--yes` | No questions. |
| `--no-restart` | Never offers a restart at the end. |

## Good to know

- Quit your apps first, especially browsers, for the best result. Files that are in use are skipped safely.
- The first launch of some apps afterwards can be a little slower while caches are rebuilt.
- Only your own caches are touched; system files and other users are left alone.

---
Part of [MozlattarScriptMaster](../../README.md) · by Mohammed AlAttar
