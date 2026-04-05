# update.sh

A single maintenance script for Arch Linux + KDE Plasma. Updates packages, cleans up cruft, and refreshes desktop/KDE databases so icons and apps stay in sync.

## Usage

```bash
chmod +x update.sh
./update.sh
```

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--verbose` | `-v` | Show detailed/debug output |
| `--dry-run` | `-n` | Preview all steps without making any changes |
| `--clear-logs` | `-c` | Delete old log files from `/tmp` and exit |
| `--help` | `-h` | Show usage info and exit |

## What It Does

| Step | Task |
|------|------|
| 1 | Update pacman, AUR (yay), and Flatpak packages |
| 2 | Remove orphan packages |
| 3 | Clean pacman and yay caches |
| 4 | Vacuum systemd journal logs (keeps last 3 days) |
| 5 | Update `locate` and `man` databases |
| 6 | Clear KDE, thumbnail, and user caches |
| 7 | Rebuild user and system desktop file databases |
| 8 | Rebuild KDE service cache (`kbuildsycoca6/5`) |

## Logs

Each run writes a timestamped log to `/tmp/system-update-YYYYMMDD-HHMMSS.log`.

To clean up old logs:
```bash
./update.sh --clear-logs
```

## Dependencies

- [`yay`](https://github.com/Jguer/yay) - AUR helper
- `flatpak` - for Flatpak package updates
- `mlocate` / `plocate` - for `updatedb`
- `man-db` - for `mandb`
- `kbuildsycoca6` or `kbuildsycoca5` - KDE cache rebuild (auto-detected)
