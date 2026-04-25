#!/usr/bin/env bash
# scribe-lint — Linux/cron version of the launchd wrapper.
# Runs a wiki health check headlessly against the Obsidian vault and logs to
# $HOME/.local/state/scribe/lint.log.
#
# Uses an inline natural-language prompt rather than the /scribe-lint slash
# command so it works whether or not the scribe plugin is currently activated
# in the headless session.
#
# Override the vault path:  SCRIBE_VAULT=/path/to/vault scribe-lint.sh

set -uo pipefail

VAULT="${SCRIBE_VAULT:-$HOME/Documents/obsidian/claude}"
LOG_DIR="$HOME/.local/state/scribe"
LOG="$LOG_DIR/lint.log"

mkdir -p "$LOG_DIR"

# Ensure typical install paths are on PATH for cron's barebones environment.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

read -r -d '' PROMPT <<'EOF' || true
You are running a scheduled health check on my Obsidian wiki located at the current working directory. The vault follows the Karpathy LLM-Wiki pattern: WIKI.md is the schema, index.md is the catalog, log.md is the chronological event log, and pages live under projects/, people/, infrastructure/, patterns/, domains/, prs/, sources/, etc.

Run these seven checks and report findings sectioned in markdown:

1. Orphan pages — markdown files that no other markdown file links to via [[wikilink]]. Exclude WIKI.md, index.md, log.md.
2. Concepts mentioned but undocumented — capitalized noun phrases or repeated terms appearing in 3+ pages without their own page.
3. Contradictions — pairs of pages making conflicting claims about the same entity with no ## History entry resolving the change.
4. Stale active — pages with frontmatter status: active whose updated: field is more than 30 days ago, or whose newest ## History entry is more than 30 days ago.
5. Missing cross-references — pages that mention an entity name without wikilinking it, where a page for that entity exists.
6. Index drift — pages on disk not listed in index.md, or index.md entries pointing to deleted pages.
7. Log drift — recent file edits with no corresponding log.md entry.

Then append a single line to log.md:
## [YYYY-MM-DD] lint | scheduled — N orphans, M stale, K contradictions

Do not auto-fix anything. Only the report and the log entry. Use Read, Grep, and Glob freely. Be concise; skip empty sections.
EOF

{
  echo "================================================================"
  echo "scribe-lint @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "vault=$VAULT"
  echo "================================================================"

  if [[ ! -d "$VAULT" ]]; then
    echo "ERROR: vault not found at $VAULT"
    exit 1
  fi

  cd "$VAULT" || exit 1
  claude -p "$PROMPT" 2>&1 || echo "claude CLI exited non-zero ($?)"

  echo "scribe-lint done @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
} >> "$LOG" 2>&1
