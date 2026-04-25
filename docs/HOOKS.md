# Background updates — three modes

scribe doesn't run as a daemon; it activates when invoked. But you can wire it into Claude Code's hooks and the schedule skill so it *feels* automatic. Three modes, in order of overhead.

## Mode A — manual (default; no setup)

Use any of these in a normal conversation:

```text
/scribe-ingest <url-or-file-or-paste>     # add a specific source
/scribe-update <fact change>               # fix or extend a page
/scribe-capture                            # scan recent turns, propose what to save
/scribe-query <question>                   # ask the wiki; non-trivial answers get filed
/scribe-lint                               # health check
```

Or in plain English — the skills activate when relevant:

```text
> save the section above to scribe
> add a page for our SF Bulk API cursor format
> mark project chain-resolution as done
```

This is the recommended default. You stay in control; the wiki only grows when you say so.

## Mode B — end-of-session capture (one hook)

Add a `Stop` hook that prompts Claude to run `/scribe-capture` automatically when a turn ends. Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Auto-capture available — run /scribe-capture if this conversation produced anything wiki-worthy.'",
            "blocking": false
          }
        ]
      }
    ]
  }
}
```

This emits a passive reminder. It does **not** auto-write — Claude won't touch the wiki without you asking. Trade-off: gentle nudge vs. zero noise.

If you want a stronger version that actually *runs* capture at session end, change the command to invoke the slash command — but only do this on conversations you know will be wiki-worthy, otherwise expect noise.

## Mode C — scheduled lint via local launchd (macOS) or cron (Linux)

⚠️ **Do not use Claude Code's `/schedule` skill for scribe.** That runs in Anthropic's cloud and can't see your local Obsidian vault. You need a *local* scheduler.

scribe is local-first (the vault lives under `~/Documents/`), so the scheduler must run on your machine. macOS uses `launchd`; Linux uses `cron`. Both invoke the headless `claude -p "/scribe-lint"` CLI mode against the vault.

### macOS — launchd (recommended)

A ready-to-install wrapper script + plist live in [`examples/launchd/`](../examples/launchd/). Two-command install:

```bash
cd examples/launchd
./install.sh
```

What the install script does:

1. Copies `scribe-lint.sh` to `~/.local/bin/` and `chmod +x`'s it.
2. Templates `dev.scribe.lint.plist` with your `$HOME` and writes it to `~/Library/LaunchAgents/`.
3. Bootstraps the launchd job — fires daily at 09:00 and 21:00 local.

Test-fire and inspect:

```bash
launchctl kickstart gui/$(id -u)/dev.scribe.lint
sleep 5
tail -30 ~/Library/Logs/scribe/lint.log
```

For reference, the wrapper at `~/.local/bin/scribe-lint.sh` looks like:

```bash
#!/bin/zsh
set -uo pipefail
VAULT="${SCRIBE_VAULT:-$HOME/Documents/obsidian/claude}"
LOG="$HOME/Library/Logs/scribe/lint.log"
mkdir -p "$(dirname "$LOG")"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

{
  echo "================================================================"
  echo "scribe-lint @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "================================================================"
  cd "$VAULT" || exit 1
  claude -p "/scribe-lint" 2>&1 || echo "claude CLI exited non-zero ($?)"
  echo "done @ $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$LOG" 2>&1
```

`chmod +x ~/.local/bin/scribe-lint.sh`.

Plist at `~/Library/LaunchAgents/dev.<you>.scribe.lint.plist` — schedules 09:00 and 21:00 daily:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.you.scribe.lint</string>
  <key>ProgramArguments</key>
  <array><string>/Users/YOU/.local/bin/scribe-lint.sh</string></array>
  <key>StartCalendarInterval</key>
  <array>
    <dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>21</integer><key>Minute</key><integer>0</integer></dict>
  </array>
  <key>StandardOutPath</key>
  <string>/Users/YOU/Library/Logs/scribe/launchd.out</string>
  <key>StandardErrorPath</key>
  <string>/Users/YOU/Library/Logs/scribe/launchd.err</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>SCRIBE_VAULT</key><string>/Users/YOU/Documents/obsidian/claude</string>
    <key>HOME</key><string>/Users/YOU</string>
  </dict>
</dict>
</plist>
```

Load:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.you.scribe.lint.plist
launchctl kickstart gui/$(id -u)/dev.you.scribe.lint   # fire once now to test
tail -30 ~/Library/Logs/scribe/lint.log
```

Unload:

```bash
launchctl bootout gui/$(id -u)/dev.you.scribe.lint
```

### Linux — cron

Equivalent script + crontab snippet in [`examples/cron/`](../examples/cron/). Install with:

```bash
cp examples/cron/scribe-lint.sh ~/.local/bin/scribe-lint.sh
chmod +x ~/.local/bin/scribe-lint.sh
crontab -e        # paste: 0 9,21 * * * $HOME/.local/bin/scribe-lint.sh
```

Logs land in `~/.local/state/scribe/lint.log`.

### Why lint, not capture, on a schedule

`scribe:capture` needs the *current conversation* to scan — there's no conversation in a headless cron run. A scheduled `lint` works because it operates over the vault's static state.

If you want periodic auto-ingest (e.g., "every morning, ingest yesterday's RSS feed"), write a wrapper that pipes URLs into `claude -p "<inline ingest prompt> for $URL"` — see the lint wrapper in `examples/launchd/scribe-lint.sh` as a template.

### Why an inline prompt, not the slash command

The wrappers pass an inline natural-language prompt to `claude -p` rather than the literal `/scribe-lint` slash command. In headless mode the plugin's slash commands aren't always recognised (you'll see "Unknown command: /scribe-lint" in the log). The inline prompt mirrors the skill's process and works whether or not the plugin is installed for the headless invocation. Trade-off: the prompt drifts slightly from the canonical SKILL.md if you don't keep them in sync — review on each scribe upgrade.

### Caveats

- `claude -p` in launchd needs the API token reachable. If your Claude Code config relies on macOS keychain that requires user login, jobs may fail when no one's logged in. Test with `launchctl kickstart` to confirm.
- The wiki edits land on disk; they don't auto-commit. Combine with Mode D if you want a git audit trail.
- Lint output is verbose. Truncate `~/Library/Logs/scribe/lint.log` periodically — `> ~/Library/Logs/scribe/lint.log` or add a logrotate config.

## Mode D — git-backed vault (optional, v0.3 roadmap)

Initialize the vault as a git repo:

```bash
cd ~/Documents/obsidian/claude
git init -b main
git add . && git commit -m "scribe: initial commit"
```

Combine with a `Stop` hook that auto-commits on every wiki-touching turn:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "if [[ \"${CLAUDE_TOOL_FILE_PATH:-}\" == */Documents/obsidian/* ]]; then cd ~/Documents/obsidian/claude && git add -A && git commit -m \"scribe: auto-commit\" --quiet || true; fi",
            "blocking": false
          }
        ]
      }
    ]
  }
}
```

This is heavier. Recommended only if you want a full audit trail of every wiki edit.

## Which mode to start with

- **Just install the plugin → start with A.** Five commands, zero config. See how it feels.
- **You finish sessions and forget to capture → add B.** One hook, passive nudge.
- **You want background hygiene → add C.** Weekly lint catches drift.
- **You want full audit history → add D.** Heavier; only if you care about per-edit provenance.

Stack them as needed: A is always on; B/C/D are independent opt-ins.

## Anti-patterns

- **Don't** install a `Stop` hook that auto-runs `/scribe-capture` on every turn — it'll fight you mid-conversation.
- **Don't** wire a `UserPromptSubmit` hook to scribe — anything it writes lands before Claude even responds, which is confusing.
- **Don't** schedule `/scribe-ingest` blindly. Ingest needs a concrete source. Schedule `lint` and `capture`; let `ingest` stay manual.
