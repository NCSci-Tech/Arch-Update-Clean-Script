#!/usr/bin/env bash
# ========================================================
#  Arch Linux Update, Cleanup & Desktop DB Refresh
#  Updates pacman/AUR/Flatpak, removes orphans, cleans
#  caches/logs, and refreshes desktop/KDE databases.
#
#  Usage: ./update.sh [--verbose] [--dry-run]
# ========================================================

set -euo pipefail

# --------------------------------------------------------
# Flags & config
# --------------------------------------------------------
VERBOSE=false
DRY_RUN=false
LOG_FILE="/tmp/system-update-$(date +%Y%m%d-%H%M%S).log"

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true; shift ;;
        --dry-run|-n) DRY_RUN=true; shift ;;
        --clear-logs|-c) # Clear old update logs from /tmp
            echo "Clearing old update logs from /tmp..."
            rm -fv /tmp/system-update-*.log
            echo "Done."
            exit 0 ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--dry-run] [--clear-logs]"
            echo "  --verbose, -v     Show detailed output"
            echo "  --dry-run, -n     Show what would be done without doing it"
            echo "  --clear-logs, -c  Remove old update logs from /tmp and exit"
            exit 0 ;;
        *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
    esac
done

# --------------------------------------------------------
# Helpers
# --------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() {
    local level=$1; shift
    local msg="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE"
    if [[ "$VERBOSE" == true ]] || [[ "$level" != "DEBUG" ]]; then
        case $level in
            ERROR)   echo -e "${RED}[ERROR]${NC} $msg" >&2 ;;
            WARN)    echo -e "${YELLOW}[WARN]${NC} $msg" ;;
            SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $msg" ;;
            INFO)    echo -e "${BLUE}[INFO]${NC} $msg" ;;
            DEBUG)   [[ "$VERBOSE" == true ]] && echo "[DEBUG] $msg" ;;
        esac
    fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

check_dir() {
    [[ -d "$1" && -r "$1" ]] || { log "WARN" "Skipping missing/unreadable dir: $1"; return 1; }
}

run() {
    local cmd="$*"
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] Would run: $cmd"; return 0
    fi
    log "DEBUG" "Running: $cmd"
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "DEBUG" "OK: $cmd"
    else
        local code=$?
        log "ERROR" "Failed (exit $code): $cmd"; return $code
    fi
}

# --------------------------------------------------------
# Main
# --------------------------------------------------------
ERRORS=0

echo "=== Arch Linux System Maintenance ==="
log "INFO" "Log: $LOG_FILE"
echo

# [1/7] Package updates
log "INFO" "[1/7] Updating pacman, AUR & Flatpak packages..."
run "yay -Syu --noconfirm"
run "flatpak update --noninteractive"

# [2/7] Orphan removal
log "INFO" "[2/7] Checking for orphan packages..."
orphans=$(pacman -Qdtq || true)
if [[ -n "$orphans" ]]; then
    log "INFO" "Removing orphans: $orphans"
    run "sudo pacman -Rns --noconfirm $orphans"
else
    log "INFO" "No orphan packages found."
fi

# [3/7] Clean pacman & yay cache
log "INFO" "[3/7] Cleaning pacman & yay caches..."
run "sudo pacman -Scc --noconfirm"
run "yay -Scc --noconfirm"

# [4/7] Journal logs
log "INFO" "[4/7] Vacuuming systemd journal (keeping 3 days)..."
run "sudo journalctl --vacuum-time=3d"

# [5/8] Update locate & man databases
log "INFO" "[5/8] Updating locate and man databases..."
run "sudo updatedb"
run "sudo mandb"

# [6/8] KDE & user caches
log "INFO" "[5/7] Removing KDE and user caches..."
run "rm -rf ~/.cache/*"
run "rm -rf ~/.local/share/ksysguard/*" || true
run "rm -rf ~/.local/share/sddm/*"      || true
run "rm -rf ~/.local/share/Trash/*"
run "rm -rf ~/.cache/yay/*"

# [6/7] Desktop database
log "INFO" "[6/7] Updating desktop file databases..."

if check_dir "$HOME/.local/share/applications"; then
    if run "update-desktop-database $HOME/.local/share/applications"; then
        log "SUCCESS" "User desktop database updated."
    else
        log "ERROR" "Failed to update user desktop database."; ((ERRORS++))
    fi
fi

if check_dir "/usr/share/applications"; then
    if [[ -w "/usr/share/applications" ]]; then
        run "update-desktop-database /usr/share/applications" \
            && log "SUCCESS" "System desktop database updated." \
            || { log "ERROR" "Failed to update system desktop database."; ((ERRORS++)); }
    else
        if [[ "$DRY_RUN" == true ]]; then
            log "INFO" "[DRY-RUN] Would run with sudo: update-desktop-database /usr/share/applications"
        else
            log "INFO" "Sudo required for system desktop database..."
            if sudo update-desktop-database /usr/share/applications >> "$LOG_FILE" 2>&1; then
                log "SUCCESS" "System desktop database updated (sudo)."
            else
                log "ERROR" "Failed to update system desktop database (sudo)."; ((ERRORS++))
            fi
        fi
    fi
fi

# [8/8] KDE sycoca cache
log "INFO" "[8/8] Rebuilding KDE service cache..."
if command_exists kbuildsycoca6; then
    run "kbuildsycoca6 --noincremental" \
        && log "SUCCESS" "KDE6 cache rebuilt." \
        || { log "ERROR" "Failed to rebuild KDE6 cache."; ((ERRORS++)); }
elif command_exists kbuildsycoca5; then
    run "kbuildsycoca5 --noincremental" \
        && log "SUCCESS" "KDE5 cache rebuilt." \
        || { log "ERROR" "Failed to rebuild KDE5 cache."; ((ERRORS++)); }
else
    log "DEBUG" "No kbuildsycoca found, skipping."
fi

# --------------------------------------------------------
# Summary
# --------------------------------------------------------
echo
if [[ $ERRORS -eq 0 ]]; then
    log "SUCCESS" "=== All done! Full log: $LOG_FILE ==="
    exit 0
else
    log "ERROR" "=== Finished with $ERRORS error(s). Check log: $LOG_FILE ==="
    exit 1
fi
