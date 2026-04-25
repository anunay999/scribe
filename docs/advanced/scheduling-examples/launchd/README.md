# Twice-daily scribe-lint via launchd (macOS)

Runs `/scribe-lint` over your Obsidian vault twice a day (09:00 and 21:00 local). Output goes to `~/Library/Logs/scribe/lint.log`.

## Install

```bash
cd docs/advanced/scheduling-examples/launchd
./install.sh
```

This:

1. Copies `scribe-lint.sh` to `~/.local/bin/scribe-lint.sh` and `chmod +x`'s it.
2. Templates `dev.scribe.lint.plist` with your `$HOME` and writes to `~/Library/LaunchAgents/dev.scribe.lint.plist`.
3. Bootstraps the launchd job under your user.

Custom vault path:

```bash
SCRIBE_VAULT="$HOME/notes/wiki" ./install.sh
```

(The wrapper script reads `SCRIBE_VAULT` at runtime; the plist sets a default that you can override by editing the plist.)

## Verify

Test-fire once without waiting for the schedule:

```bash
launchctl kickstart gui/$(id -u)/dev.scribe.lint
sleep 5
tail -30 ~/Library/Logs/scribe/lint.log
```

Inspect job state:

```bash
launchctl print gui/$(id -u)/dev.scribe.lint
```

## Change cadence

Edit `~/Library/LaunchAgents/dev.scribe.lint.plist` — the `StartCalendarInterval` array. Each `<dict>` is a fire time:

```xml
<dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
<dict><key>Hour</key><integer>21</integer><key>Minute</key><integer>0</integer></dict>
```

Add or remove entries, then reload:

```bash
launchctl bootout gui/$(id -u)/dev.scribe.lint
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dev.scribe.lint.plist
```

## Uninstall

```bash
launchctl bootout gui/$(id -u)/dev.scribe.lint
rm ~/Library/LaunchAgents/dev.scribe.lint.plist
rm ~/.local/bin/scribe-lint.sh
```

The vault and logs stay; delete `~/Library/Logs/scribe/` if you want them gone too.

## Troubleshooting

**Job runs but log is empty.** `claude` CLI not on PATH inside launchd's environment. Edit `scribe-lint.sh` and add the absolute path to `claude` (find it with `which claude` outside launchd).

**Job doesn't fire.** Check `launchctl print gui/$(id -u)/dev.scribe.lint` for the next fire time and any error messages. macOS sometimes won't fire jobs if the Mac is asleep at the trigger time — launchd retries on next wake.

**Auth errors in the log.** `claude -p` needs whatever auth your interactive Claude Code uses. If you're on Claude.ai login (keychain-backed), launchd can usually access it after first interactive login per session. API-key based auth via env var is more reliable for headless — set `ANTHROPIC_API_KEY` in the plist's `EnvironmentVariables`.

**Excess noise in the log.** Lint output is verbose. Truncate periodically: `> ~/Library/Logs/scribe/lint.log`. Or add a logrotate config (e.g., `newsyslog.conf` on macOS).

## Security note

This is a persistent agent that invokes `claude -p` on a schedule with full access to your vault. Treat it like any other launchd job: only install on trusted machines, and prefer a vault path you can reason about (i.e., not your entire `$HOME`).
