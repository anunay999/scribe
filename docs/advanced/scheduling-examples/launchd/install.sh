#!/bin/zsh
# Installs the scribe-lint launchd job under the current user.
#
# Usage:
#   ./install.sh                  # install with defaults
#   SCRIBE_VAULT=/p/to/vault ./install.sh
#
# What it does:
#   1. Copies scribe-lint.sh to ~/.local/bin/ (chmod +x).
#   2. Templates ~/Library/LaunchAgents/dev.scribe.lint.plist with $HOME.
#   3. Bootstraps the launchd job. Two firings per day: 09:00 and 21:00.
#
# Uninstall:
#   launchctl bootout gui/$(id -u)/dev.scribe.lint
#   rm ~/Library/LaunchAgents/dev.scribe.lint.plist ~/.local/bin/scribe-lint.sh

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin/scribe-lint.sh"
PLIST="$HOME/Library/LaunchAgents/dev.scribe.lint.plist"
LOG_DIR="$HOME/Library/Logs/scribe"

mkdir -p "$(dirname "$BIN")" "$(dirname "$PLIST")" "$LOG_DIR"

echo "Installing wrapper to $BIN"
cp "$HERE/scribe-lint.sh" "$BIN"
chmod +x "$BIN"

echo "Templating plist to $PLIST"
sed "s|__HOME__|$HOME|g" "$HERE/dev.scribe.lint.plist" > "$PLIST"

echo "Loading launchd job"
launchctl bootstrap gui/"$(id -u)" "$PLIST" 2>&1 || {
  echo
  echo "  Note: bootstrap may report 'already loaded' if you've installed before."
  echo "  To replace: launchctl bootout gui/\$(id -u)/dev.scribe.lint && launchctl bootstrap gui/\$(id -u) $PLIST"
}

echo
echo "Installed. Test-fire once with:"
echo "  launchctl kickstart gui/\$(id -u)/dev.scribe.lint"
echo "  tail -30 $LOG_DIR/lint.log"
echo
echo "Schedule: 09:00 and 21:00 local time, daily."
echo "Vault: ${SCRIBE_VAULT:-$HOME/Documents/obsidian/claude}"
