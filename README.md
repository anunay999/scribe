# scribe

> Claude as your scribe — reads what you read, writes it down, keeps it linked, never forgets.

A Claude Code plugin that turns Claude into the maintainer of a persistent, interlinked Obsidian-friendly markdown wiki. Pattern: [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — three layers (raw sources / wiki / schema), index + log indexing, ingest/query/lint workflows.

> **One-liner.** `/scribe-bootstrap` once. Then drop sources at Claude, ask questions, and the wiki keeps itself current. Cross-references, summaries, contradictions — Claude does the bookkeeping.

## What you get

Six slash commands and matching skills:

| Command | Skill | What it does |
|---|---|---|
| `/scribe-bootstrap` | `scribe:bootstrap` | One-time setup: creates the vault under `~/Documents/obsidian/<vault>/`, writes `WIKI.md` (schema), `index.md`, `log.md`, and seeds folders. |
| `/scribe-ingest <source>` | `scribe:ingest` | Reads a URL/file/paste, summarizes, files raw under `sources/`, updates affected pages, appends to log. |
| `/scribe-capture` | `scribe:capture` | Scans the *current conversation* for wiki-worthy content (decisions, facts, gotchas, new concepts, sources) and proposes a checklist of what to save. |
| `/scribe-query <question>` | `scribe:query` | Answers from the wiki with citations; files good answers back as new pages. |
| `/scribe-lint` | `scribe:lint` | Health check: orphan pages, contradictions, stale claims, missing cross-refs, suggestions for new pages. |
| `/scribe-update <page>` | `scribe:update` | Edit a page in place + propagate the change to linked pages + append to log. |

For an optional end-of-session nudge hook see [docs/HOOKS.md](docs/HOOKS.md). For power-user scheduled lint via launchd/cron see [docs/advanced/scheduling-examples/](docs/advanced/scheduling-examples/).

## Install

### From the marketplace

```bash
/marketplace add anunay999/scribe
/install scribe@scribe
```

(Replace `anunay999` with the GitHub org/user you publish under.)

### Local install (development)

```bash
git clone https://github.com/<you>/scribe ~/dev/scribe
/marketplace add ~/dev/scribe
/install scribe@scribe
```

## Quick start

```text
/scribe-bootstrap
   → asks for vault root (default ~/Documents/obsidian/claude/)
   → asks 2-3 questions about what you want the wiki to be (research, work, personal)
   → seeds WIKI.md / index.md / log.md / folders
```

Then for everything else, just talk:

```text
> here's a gist I want indexed: https://...
> ingest the meeting transcript I just dropped at sources/2026-04-25.md
> query: how does our sync layer handle retries?
> lint
```

The skills handle the rest — finding affected pages, updating cross-references, keeping `index.md` current, appending log entries.

## Layout it produces

```
~/Documents/obsidian/<vault>/
├── WIKI.md           # schema & conventions (the "CLAUDE.md" of the wiki)
├── index.md          # catalog of pages
├── log.md            # chronological event log
├── projects/         # active and completed work
├── people/           # stakeholders, collaborators
├── infrastructure/   # systems, services, environments
├── patterns/         # rules, conventions, working agreements
├── domains/          # long-lived systems
├── prs/              # per-PR notes
├── sources/          # raw inputs (immutable)
└── assets/           # images, diagrams
```

## Why a wiki, not RAG

RAG retrieves chunks at query time — every question rebuilds knowledge from scratch. A wiki *compounds*: cross-references are already there, contradictions are already flagged, the synthesis already reflects everything you've fed it. Claude does the bookkeeping that humans always abandon.

Karpathy's framing: **Obsidian is the IDE; the LLM is the programmer; the wiki is the codebase.**

## Memory layering

This plugin's wiki coexists with Claude Code's built-in auto-memory (`~/.claude/projects/.../memory/`):

- **Auto-memory** — small, preloaded into every session, hard rules and pointers.
- **Wiki** — large, on-demand, deeply linked, queried when topic-relevant.

`/scribe-bootstrap` adds a memory pointer so Claude knows the wiki exists in future sessions.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgements

- Pattern: [Andrej Karpathy's LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
- Skill structure inspired by Anthropic's [superpowers](https://github.com/anthropics/claude-plugins-official) plugin layout.
- Author: Anunay (mail@anunay.dev).
