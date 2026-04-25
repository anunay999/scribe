# llm-wiki-claude — plan & roadmap

## Goal

Ship a Claude Code plugin that any user can install in 30 seconds and have an LLM-maintained Obsidian wiki running by the end of their first conversation. Pattern: [Karpathy's LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Design principles

1. **Friction is the enemy.** Bootstrap must be one command, with sane defaults, and three optional clarifying questions max.
2. **Compounding > retrieval.** The wiki is a *persistent compounding artifact*. Every ingest leaves the wiki richer; every query that does real synthesis files its answer back as a page.
3. **Convention over configuration.** Folder layout, frontmatter shape, log format are fixed. Users can extend; they shouldn't have to design the basics.
4. **Idempotent skills.** `wiki-bootstrap` on an existing vault must ask before overwriting. `wiki-ingest` must detect already-ingested sources. `wiki-update` must never silently drop history.
5. **No magic, no auto-fix without consent.** Lint surfaces problems; user picks what gets touched.

## Architecture

### Plugin layout

```
llm-wiki-claude/
├── README.md
├── PLAN.md                    (this file)
├── LICENSE
├── CHANGELOG.md
├── .gitignore
├── .claude-plugin/
│   └── marketplace.json       (marketplace listing — installs the plugin under it)
├── plugins/
│   └── llm-wiki/
│       ├── plugin.json
│       ├── skills/
│       │   ├── wiki-bootstrap/SKILL.md
│       │   ├── wiki-ingest/SKILL.md
│       │   ├── wiki-query/SKILL.md
│       │   ├── wiki-lint/SKILL.md
│       │   └── wiki-update/SKILL.md
│       └── commands/
│           ├── wiki-bootstrap.md
│           ├── wiki-ingest.md
│           ├── wiki-query.md
│           ├── wiki-lint.md
│           └── wiki-update.md
└── docs/
    ├── INSTALL.md
    ├── PROMPT.md              (the bootstrap "detailed prompt" the user can copy/paste anywhere)
    └── EXAMPLES.md
```

### Skills

Five rigid-process skills, one per workflow. Skill descriptions are written for Claude — they're activation hints, not user-facing copy.

| Skill | Trigger | Process |
|---|---|---|
| `wiki-bootstrap` | "set up a wiki", "create a knowledge base under ~/Documents/obsidian/..." | 6 steps: gather → verify → seed folders → write WIKI.md/index.md/log.md → wire memory pointer → confirm |
| `wiki-ingest` | "ingest <url/file/paste>", "add this source to the wiki" | 6 steps: fetch+slug → write raw → propagate → update index → log → discuss |
| `wiki-query` | "what does the wiki say about X?", "compare X and Y from the wiki" | 5 steps: read index → read candidates → synthesize → file-back if non-trivial → confirm |
| `wiki-lint` | "lint the wiki", "health-check" | 4 steps: gather → 7 checks → report → offer fixes |
| `wiki-update` | "update the page about X", "mark project Y as done" | 6 steps: locate → edit → propagate → history → log → confirm |

### Commands

Each skill has a matching slash command. Commands are 3-line wrappers that invoke the skill with `$ARGUMENTS`.

### Marketplace listing

`.claude-plugin/marketplace.json` declares one plugin (`llm-wiki`) at `./plugins/llm-wiki`. When a user runs `/marketplace add anunay-aatipamula/llm-wiki-claude`, Claude Code reads this file and offers the plugin for install.

## Roadmap

### v0.1.0 — MVP (this release)

- Five skills above.
- Five slash commands.
- Marketplace listing.
- README + PLAN + INSTALL + PROMPT + EXAMPLES docs.
- Tested locally by installing into Claude Code and running through the workflows.

### v0.2.0 — quality of life

- `wiki-search` skill: a CLI helper that does BM25 + vector + LLM rerank over the vault (or shell out to [qmd](https://github.com/tobi/qmd) when available). Reduces token cost for `wiki-query` on large vaults.
- `wiki-bootstrap` accepts a `--seed-from-memory` flag that imports the user's existing `~/.claude/projects/.../memory/` content as seed pages.
- Per-domain templates: research / personal / book overlays seed extra folders + example pages.

### v0.3.0 — durability

- `wiki-sync` skill: optional periodic `git commit` of the vault, with a per-vault git config.
- `wiki-export`: render selected pages into a Marp slide deck or PDF.
- A CronCreate-backed daily lint reminder (opt-in).

### v0.4.0 — multi-source intelligence

- `wiki-ingest` learns to detect related-source dedup ("you already ingested a similar page from the same author last month — merge?").
- `wiki-lint` adds a `coverage` check — surfaces topics from `index.md` headings that have <3 pages, suggesting research gaps.

## Setup (local development)

```bash
# 1. Clone or open the project
cd ~/dev/llm-wiki-claude

# 2. Add your local checkout as a Claude Code marketplace
#    (in any Claude Code session)
/marketplace add ~/dev/llm-wiki-claude

# 3. Install the plugin
/install llm-wiki@llm-wiki-claude

# 4. Run the bootstrap once
/wiki-bootstrap

# 5. Iterate on skills/SKILL.md, commands/*.md, then reload
/marketplace reload
```

Skills auto-reload on next session start. Commands need a `/marketplace reload` to pick up edits.

## Publishing

1. **Repository**: `github.com/anunay-aatipamula/llm-wiki-claude` (or your org).
2. **Tag** a release: `v0.1.0`. The marketplace listing references the repo, not a tag — but tagging gives users a clean version handle.
3. **Submit** to the Claude Code marketplace registry (TBD by Anthropic — at the time of writing, marketplace adds are by URL: `/marketplace add <gh-owner>/<repo>`). If Anthropic launches a curated marketplace, register there too.
4. **Announce**: README on GitHub + a short post linking back to the Karpathy gist for context.

## Testing checklist (before tagging v0.1.0)

- [ ] `/wiki-bootstrap` from scratch creates a vault that opens cleanly in Obsidian (graph view shows index ↔ WIKI ↔ log).
- [ ] `/wiki-bootstrap` on an existing vault with `WIKI.md` asks before overwriting.
- [ ] `/wiki-ingest <url>` produces a `sources/<slug>.md` with TL;DR, updates ≥1 wiki page, appends to log.
- [ ] `/wiki-ingest <same url>` again is a no-op or asks "refresh?"
- [ ] `/wiki-query` answers with `[[wikilink]]` citations only — no fabricated pages.
- [ ] `/wiki-query` files a synthesis page when the answer touches 4+ source pages.
- [ ] `/wiki-lint` surfaces a known orphan, a known stale page, a known undocumented concept.
- [ ] `/wiki-update` edits in place + appends `## History` + appends to log.
- [ ] Memory pointer added to `~/.claude/projects/<project>/memory/MEMORY.md`.

## Open questions

- **Vault discovery across sessions.** Right now `wiki-bootstrap` writes the path into the auto-memory pointer. Better: a `~/.config/llm-wiki/vaults.json` registry so the user can have multiple vaults and the skill picks the right one by project context.
- **Multi-vault support.** v0.1 assumes one vault. v0.2 should let `/wiki-query --vault=research` pick.
- **Concurrency.** What happens if two Claude Code sessions edit the same vault simultaneously? File-level conflicts. Probably solved by git-backed vaults in v0.3.

## Related

- [Karpathy LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [Anthropic claude-plugins-official](https://github.com/anthropics/claude-plugins-official)
- [qmd — local markdown search](https://github.com/tobi/qmd)
