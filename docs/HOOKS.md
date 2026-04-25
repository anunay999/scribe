# Background updates — keep it simple

scribe doesn't run as a daemon. It activates when invoked. Two recommended modes:

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

## Mode B — end-of-session nudge (one hook)

Add a `Stop` hook that prints a passive reminder when a turn ends. In `~/.claude/settings.json`:

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

This emits a passive reminder. It does **not** auto-write — Claude won't touch the wiki without you asking.

## Anti-patterns

- **Don't** install a `Stop` hook that auto-runs `/scribe-capture` on every turn — it'll fight you mid-conversation.
- **Don't** wire a `UserPromptSubmit` hook to scribe — anything it writes lands before Claude responds, which is confusing.
- **Don't** schedule `/scribe-ingest` blindly. Ingest needs a concrete source.

## Power-user: scheduled lint

If you want twice-daily background hygiene via macOS launchd or Linux cron, see [advanced/scheduling-examples/](advanced/scheduling-examples/). Heads-up: it's real config work (plist templating, headless `claude -p` quirks). Most users don't need it — manual `/scribe-lint` when you remember is fine.
