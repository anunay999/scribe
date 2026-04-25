# Changelog

All notable changes to llm-wiki-claude.

## [0.1.0] — 2026-04-25

### Added

- Five skills: `wiki-bootstrap`, `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-update`.
- Five matching slash commands.
- Marketplace listing at `.claude-plugin/marketplace.json`.
- `README.md`, `PLAN.md`, `docs/INSTALL.md`, `docs/PROMPT.md`, `docs/EXAMPLES.md`.

### Notes

Implements [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern. Default vault: `~/Documents/obsidian/claude/`. Auto-memory pointer wired by `wiki-bootstrap`.
