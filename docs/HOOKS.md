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

## Mode C — scheduled lint + ingest (cron)

Use Claude Code's `schedule` skill to run periodic maintenance:

```text
> /schedule every monday at 9am run /scribe-lint
> /schedule every sunday at 8pm run /scribe-capture for the past week
```

This runs in Anthropic's cloud — independent of whether you have a session open. Good for:

- Weekly lint that surfaces stale `#active` projects.
- Monthly capture pass over a working area.

Schedules are listed via `/schedule list`, removed via `/schedule remove <id>`.

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
