# Changelog

All notable changes to scribe.

## [0.1.3] — 2026-04-25

### Changed

- Simplified default story to manual + optional Stop-hook nudge. Scheduled lint configs moved out of the README path into `docs/advanced/scheduling-examples/` for power users. Setting up launchd/cron from scratch was too much friction for most users; the manual `/scribe-lint` workflow covers the same need with zero config.
- `docs/HOOKS.md` slimmed to Modes A and B only. Mode C (launchd/cron) and Mode D (git-backed vault) are referenced from the advanced directory.

## [0.1.2] — 2026-04-25

### Added

- `examples/launchd/` — ready-to-install macOS launchd job for twice-daily `scribe-lint` (09:00 + 21:00). Includes `install.sh`, the wrapper script, and the templated plist. One-liner install: `cd examples/launchd && ./install.sh`.
- `examples/cron/` — Linux/cron equivalent with `crontab.example`.
- HOOKS.md now points at the example files and explains the slash-command-vs-inline-prompt trade-off in headless mode.

### Fixed

- The wrapper scripts use an inline natural-language prompt instead of `claude -p "/scribe-lint"`. Slash commands aren't reliably recognised in headless `-p` mode ("Unknown command: /scribe-lint"); the inline prompt mirrors the skill's seven checks and works whether or not the plugin is currently activated.

## [0.1.1] — 2026-04-25

### Added

- New skill + command: `scribe:capture` / `/scribe-capture` — scans the current conversation for wiki-worthy content (decisions, facts, gotchas, new concepts, sources) and proposes a checklist of what to save.
- `docs/HOOKS.md` — three modes for keeping the wiki current automatically: manual, end-of-session capture hook, scheduled lint/capture, and optional git-backed auto-commit.

### Fixed

- `plugin.json` author field is now an object (`{name, email, url}`) per the Claude Code plugin schema, fixing the "Validation errors: author: Invalid input: expected object, received string" install error.
- Author email updated to mail@anunay.dev across plugin.json and marketplace.json.

## [0.1.0] — 2026-04-25

### Added

- Five skills: `bootstrap`, `ingest`, `query`, `lint`, `update`.
- Five matching slash commands.
- Marketplace listing at `.claude-plugin/marketplace.json`.
- `README.md`, `PLAN.md`, `docs/INSTALL.md`, `docs/PROMPT.md`, `docs/EXAMPLES.md`.

### Notes

Implements [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern. Default vault: `~/Documents/obsidian/claude/`. Auto-memory pointer wired by `bootstrap`.
