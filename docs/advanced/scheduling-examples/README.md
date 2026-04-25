# Scheduling examples (advanced / optional)

These are reference configs for users who want twice-daily background `scribe-lint` runs. **You don't need this for normal scribe use** — manual `/scribe-lint` works fine.

Trade-offs before you go down this path:

- launchd/cron jobs run `claude -p` headless. Plugin slash commands aren't always recognized in headless mode, so the wrappers use an inline natural-language prompt that mirrors the lint skill. If the skill changes, update the wrapper.
- `claude -p` needs API credentials reachable from the scheduler context. macOS keychain that requires user login can fail when no one's logged in.
- The wiki is on disk; it doesn't auto-commit. Add a separate git hook if you want an audit trail.
- Lint logs are verbose. Truncate periodically.

## macOS — launchd

See [`launchd/`](launchd/). Two-command install:

```bash
cd launchd
./install.sh
```

What it does:
1. Copies `scribe-lint.sh` to `~/.local/bin/`.
2. Templates `dev.scribe.lint.plist` with your `$HOME` and writes it to `~/Library/LaunchAgents/`.
3. Bootstraps the launchd job — fires daily at 09:00 and 21:00 local.

Test fire and inspect:

```bash
launchctl kickstart gui/$(id -u)/dev.scribe.lint
tail -60 ~/Library/Logs/scribe/lint.log
```

Unload:

```bash
launchctl bootout gui/$(id -u)/dev.scribe.lint
```

## Linux — cron

See [`cron/`](cron/). Install:

```bash
cp cron/scribe-lint.sh ~/.local/bin/scribe-lint.sh
chmod +x ~/.local/bin/scribe-lint.sh
crontab -e   # paste: 0 9,21 * * * $HOME/.local/bin/scribe-lint.sh
```

Logs land in `~/.local/state/scribe/lint.log`.

## Why lint, not capture, on a schedule

`scribe:capture` needs the *current conversation* to scan — there's no conversation in a headless cron run. Scheduled `lint` works because it operates over the vault's static state.
