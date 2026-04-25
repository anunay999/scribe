# scribe — plan & roadmap

## Goal

Ship a Claude Code plugin that any user can install in 30 seconds and have an LLM-maintained Obsidian wiki running by the end of their first conversation. Pattern: [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Design principles

1. **Friction is the enemy.** Bootstrap must be one command, with sane defaults, and three optional clarifying questions max.
2. **Compounding > retrieval.** The wiki is a *persistent compounding artifact*. Every ingest leaves the wiki richer; every query that does real synthesis files its answer back as a page.
3. **Convention over configuration.** Folder layout, frontmatter shape, log format are fixed. Users can extend; they shouldn't have to design the basics.
4. **Idempotent skills.** `bootstrap` on an existing vault must ask before overwriting. `ingest` must detect already-ingested sources. `update` must never silently drop history.
5. **No magic, no auto-fix without consent.** Lint surfaces problems; user picks what gets touched.

## Architecture

### Plugin layout

```
scribe/
├── README.md
├── PLAN.md                    (this file)
├── LICENSE
├── CHANGELOG.md
├── .gitignore
├── .claude-plugin/
│   └── marketplace.json       (marketplace listing — installs the plugin under it)
├── plugins/
│   └── scribe/
│       ├── plugin.json
│       ├── skills/
│       │   ├── bootstrap/SKILL.md
│       │   ├── ingest/SKILL.md
│       │   ├── query/SKILL.md
│       │   ├── lint/SKILL.md
│       │   └── update/SKILL.md
│       └── commands/
│           ├── scribe-bootstrap.md
│           ├── scribe-ingest.md
│           ├── scribe-query.md
│           ├── scribe-lint.md
│           └── scribe-update.md
└── docs/
    ├── INSTALL.md
    ├── PROMPT.md              (the bootstrap "detailed prompt" the user can copy/paste anywhere)
    └── EXAMPLES.md
```

### Skills

Five rigid-process skills, one per workflow. Skill descriptions are written for Claude — they're activation hints, not user-facing copy.

| Skill | Trigger | Process |
|---|---|---|
| `bootstrap` | "set up a wiki", "create a knowledge base under ~/Documents/obsidian/..." | 6 steps: gather → verify → seed folders → write WIKI.md/index.md/log.md → wire memory pointer → confirm |
| `ingest` | "ingest <url/file/paste>", "add this source to the wiki" | 6 steps: fetch+slug → write raw → propagate → update index → log → discuss |
| `query` | "what does the wiki say about X?", "compare X and Y from the wiki" | 5 steps: read index → read candidates → synthesize → file-back if non-trivial → confirm |
| `lint` | "lint the wiki", "health-check" | 4 steps: gather → 7 checks → report → offer fixes |
| `update` | "update the page about X", "mark project Y as done" | 6 steps: locate → edit → propagate → history → log → confirm |

### Commands

Each skill has a matching slash command. Commands are 3-line wrappers that invoke the skill with `$ARGUMENTS`.

### Marketplace listing

`.claude-plugin/marketplace.json` declares one plugin (`scribe`) at `./plugins/scribe`. When a user runs `/marketplace add anunay999/scribe`, Claude Code reads this file and offers the plugin for install.

## Roadmap

### v0.1.0 — MVP (this release)

- Five skills above.
- Five slash commands.
- Marketplace listing.
- README + PLAN + INSTALL + PROMPT + EXAMPLES docs.
- Tested locally by installing into Claude Code and running through the workflows.

### v0.2.0 — quality of life

- `wiki-search` skill: a CLI helper that does BM25 + vector + LLM rerank over the vault (or shell out to [qmd](https://github.com/tobi/qmd) when available). Reduces token cost for `query` on large vaults.
- `bootstrap` accepts a `--seed-from-memory` flag that imports the user's existing `~/.claude/projects/.../memory/` content as seed pages.
- Per-domain templates: research / personal / book overlays seed extra folders + example pages.

### v0.3.0 — durability

- `wiki-sync` skill: optional periodic `git commit` of the vault, with a per-vault git config.
- `wiki-export`: render selected pages into a Marp slide deck or PDF.
- A CronCreate-backed daily lint reminder (opt-in).

### v0.4.0 — multi-source intelligence

- `ingest` learns to detect related-source dedup ("you already ingested a similar page from the same author last month — merge?").
- `lint` adds a `coverage` check — surfaces topics from `index.md` headings that have <3 pages, suggesting research gaps.

## Setup (local development)

```bash
# 1. Clone or open the project
cd ~/dev/scribe

# 2. Add your local checkout as a Claude Code marketplace
#    (in any Claude Code session)
/marketplace add ~/dev/scribe

# 3. Install the plugin
/install scribe@scribe

# 4. Run the bootstrap once
/scribe-bootstrap

# 5. Iterate on skills/SKILL.md, commands/*.md, then reload
/marketplace reload
```

Skills auto-reload on next session start. Commands need a `/marketplace reload` to pick up edits.

## Publishing

1. **Repository**: `github.com/anunay999/scribe` (or your org).
2. **Tag** a release: `v0.1.0`. The marketplace listing references the repo, not a tag — but tagging gives users a clean version handle.
3. **Submit** to the Claude Code marketplace registry (TBD by Anthropic — at the time of writing, marketplace adds are by URL: `/marketplace add <gh-owner>/<repo>`). If Anthropic launches a curated marketplace, register there too.
4. **Announce**: README on GitHub + a short post linking back to the Karpathy gist for context.

## Testing checklist (before tagging v0.1.0)

- [ ] `/scribe-bootstrap` from scratch creates a vault that opens cleanly in Obsidian (graph view shows index ↔ WIKI ↔ log).
- [ ] `/scribe-bootstrap` on an existing vault with `WIKI.md` asks before overwriting.
- [ ] `/scribe-ingest <url>` produces a `sources/<slug>.md` with TL;DR, updates ≥1 wiki page, appends to log.
- [ ] `/scribe-ingest <same url>` again is a no-op or asks "refresh?"
- [ ] `/scribe-query` answers with `[[wikilink]]` citations only — no fabricated pages.
- [ ] `/scribe-query` files a synthesis page when the answer touches 4+ source pages.
- [ ] `/scribe-lint` surfaces a known orphan, a known stale page, a known undocumented concept.
- [ ] `/scribe-update` edits in place + appends `## History` + appends to log.
- [ ] Memory pointer added to `~/.claude/projects/<project>/memory/MEMORY.md`.

## Open questions

- **Vault discovery across sessions.** Right now `bootstrap` writes the path into the auto-memory pointer. Better: a `~/.config/scribe/vaults.json` registry so the user can have multiple vaults and the skill picks the right one by project context.
- **Multi-vault support.** v0.1 assumes one vault. v0.2 should let `/scribe-query --vault=research` pick.
- **Concurrency.** What happens if two Claude Code sessions edit the same vault simultaneously? File-level conflicts. Probably solved by git-backed vaults in v0.3.

## Related

- [Karpathy Karpathy LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [Anthropic claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- [qmd — local markdown search](https://github.com/tobi/qmd)
