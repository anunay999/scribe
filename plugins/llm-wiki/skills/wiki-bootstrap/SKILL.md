---
name: wiki-bootstrap
description: Use when the user wants to set up a new LLM-maintained knowledge wiki. Creates the vault directory under ~/Documents/obsidian/<name>/, writes WIKI.md (schema), index.md (catalog), log.md (event log), and seeds folders. Adds a pointer to the wiki from Claude's auto-memory so future sessions discover it.
---

# wiki-bootstrap

> **Run this once per vault.** Subsequent sessions read `WIKI.md` and operate from there.

## What this skill does

Creates a Karpathy-style LLM-maintained wiki under an Obsidian-friendly directory. Three layers:

1. **Raw sources** — `sources/`, immutable. User drops things here.
2. **The wiki** — everything else, Claude-authored, cross-linked.
3. **The schema** — `WIKI.md`, the operating manual every future session reads first.

## Process

### Step 1 — gather context (3 questions max)

Ask, in order, only if not already supplied in the user's request:

1. **Vault root**? Default `~/Documents/obsidian/claude/`. Accept any absolute path under `~/Documents/`.
2. **Domain**? One of: `work`, `research`, `personal`, `book`, `mixed`. Drives which folder set is seeded.
3. **Top topics** (2–4 short)? E.g. for work: "data pipelines", "frontend app", "infra". For research: "transformer scaling", "RL alignment".

If the user already gave a clear directive ("set up a wiki under `~/Documents/obsidian/claude/` for my Orbital work"), skip the questions and proceed.

### Step 2 — verify writability

```bash
mkdir -p <vault_root>
test -d <vault_root> && touch <vault_root>/.test && rm <vault_root>/.test
```

If the test fails (sandbox blocks `~/Documents` reads on macOS, for example), the *write* may still succeed even though `ls` is blocked. Confirm with `test -f`. If write itself fails, escalate to the user — do not silently fall back to a different path.

### Step 3 — create folder skeleton

Standard set:

```
projects/
people/
infrastructure/
patterns/
domains/
prs/
sources/
assets/
```

Domain-specific overlays:

| Domain | Add |
|---|---|
| `research` | `papers/`, `concepts/`, `experiments/` |
| `personal` | `journal/`, `goals/`, `health/` |
| `book` | `chapters/`, `characters/`, `themes/` |
| `mixed` | (use the standard set; user can add later) |

### Step 4 — write the seed files

Three files, all with YAML frontmatter:

- `WIKI.md` — schema & conventions. Use the template in `assets/wiki-template.md` of this skill (see below).
- `index.md` — empty catalog with placeholder sections.
- `log.md` — first entry: `## [<today>] bootstrap | Wiki initialized`.

The `WIKI.md` template (substitute `{{vault_root}}`, `{{today}}`, `{{domain}}`):

```markdown
---
title: Wiki Schema & Conventions
type: schema
updated: {{today}}
---

# {{domain | title}} Wiki — Schema & Conventions

This wiki is a persistent, compounding knowledge base maintained by Claude across sessions. Pattern: Karpathy's LLM Wiki gist.

> **For Claude reading this in a new session**: read [[index]] first to see what exists, then drill into specific pages. Update pages as you learn things; don't wait for permission to add a cross-reference or fix a stale claim.

## Three layers

1. **Raw sources** (`sources/`) — articles, gists, transcripts user drops in. Immutable.
2. **The wiki** (everything else) — Claude-authored markdown, fully linked.
3. **The schema** (this file + [[index]] + [[log]]) — how the wiki is organized.

## Folder layout

(Insert the per-domain folder table generated in Step 3.)

## Page conventions

### Frontmatter

```yaml
---
title: <human-readable title>
type: project | person | infra | pattern | domain | pr | source | concept
status: active | done | planned | stale
tags: [topic, area]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### Body
1. **TL;DR** — 2–4 sentences.
2. **Context** — why it exists, how it connects.
3. **Details** — code paths, decisions, numbers.
4. **Related** — outbound `[[wikilinks]]`.
5. **History** — append-only for long-lived pages.

### Linking

Use `[[Page Title]]` for internal links. `[[Page Title|display]]` to retitle. Backlinks are automatic. Link aggressively — every entity, system, file path with its own page should be linked.

### Tags

Sparingly. Cross-cutting only: `#active`, `#stale`, `#decision`, `#bug`, `#pattern`.

## Workflows

### Ingest

User drops a source → run `/wiki-ingest`:

1. Save raw to `sources/<slug>.md` with `type: source` frontmatter.
2. Read once, summarize at top of the source page.
3. Update or create affected wiki pages.
4. Update [[index]] catalog.
5. Append `## [<today>] ingest | <Title> ([[sources/slug]])` to [[log]].

### Query

User asks something → run `/wiki-query`:

1. Read [[index]] first.
2. Pull relevant pages.
3. Answer with `[[wikilink]]` citations.
4. **File non-trivial answers back into the wiki** as new pages. Don't lose exploration to chat history.

### Update

A fact changes → run `/wiki-update <page>`:

1. Edit the page in place.
2. Append `## History` entry.
3. Append to [[log]].
4. Touch contradicting pages: mark `#stale` or fix.

### Lint

Periodically → run `/wiki-lint`:

- Orphan pages (no inbound links).
- Concepts mentioned in 3+ pages without their own page.
- Contradictions across pages.
- `#active` projects with no edits in 30+ days.
- New questions worth investigating.

## Tips for Claude

- Open [[index]] at session start when topic is non-trivial.
- New page → link from at least one existing page. No orphans.
- Surprising fact → write it down *now*. Don't trust "I'll remember."
- Many small linked pages > one giant page.
- File paths as `path/to/file.py:123` so editors can jump.
- Dates absolute. "Thursday" → `YYYY-MM-DD` before writing.

## Related

- [[index]]
- [[log]]
```

The `index.md` skeleton:

```markdown
---
title: Index
type: index
updated: {{today}}
---

# Index

Catalog of every page. See [[WIKI]] for schema, [[log]] for history.

## People

(empty — add via /wiki-ingest)

## Domains

(empty)

## Projects

### Active

### Planned

### Completed

## Patterns

## Sources

## Meta

- [[WIKI]]
- [[log]]
```

The `log.md` skeleton:

```markdown
---
title: Event Log
type: log
updated: {{today}}
---

# Event Log

Append-only chronological record. Newest first. `## [YYYY-MM-DD] <kind> | <title>`. Kinds: `ingest`, `query`, `lint`, `update`, `bootstrap`, `decision`.

> Parseable: `grep "^## \[" log.md | head -20`.

---

## [{{today}}] bootstrap | Wiki initialized

Vault: `{{vault_root}}`. Domain: `{{domain}}`. Topics: {{topics}}.

Seed files: [[WIKI]], [[index]], [[log]]. Folder set: {{folders}}.
```

### Step 5 — wire memory pointer

So future Claude sessions discover the wiki even on fresh contexts:

- File: `~/.claude/projects/<project>/memory/MEMORY.md` (the auto-loaded index Claude Code keeps).
- Add (or create) a one-line entry pointing at the new vault:

```
- [obsidian-wiki](<vault_root>/index.md) — deep linked knowledge base, consult for project/system/decision context
```

If `MEMORY.md` doesn't exist for the current project, create it with that one line plus a short header. Don't overwrite existing memory.

### Step 6 — confirm to the user

Single-paragraph confirmation: vault path, count of files written, where to start (`open <vault_root>/index.md` in Obsidian). Hand them three example next-step commands they can copy:

```
/wiki-ingest <url-or-path>     # add a source
/wiki-query <question>         # ask the wiki
/wiki-lint                     # health check
```

## Anti-patterns

- **Don't** overwrite an existing `WIKI.md` without explicit confirmation. If the vault already has one, ask: extend, replace, or pick a different vault root?
- **Don't** auto-import existing memory contents into the wiki without surfacing it. Ask: "Should I seed the wiki from your auto-memory?" If yes, summarize one entry per page rather than dumping verbatim.
- **Don't** create folders for domains the user didn't ask for ("just in case"). They become orphan clutter.

## Output

When done, the vault tree should look like:

```
<vault_root>/
├── WIKI.md
├── index.md
├── log.md
├── projects/      (empty)
├── people/        (empty)
├── infrastructure/  (empty)
├── patterns/      (empty)
├── domains/       (empty)
├── prs/           (empty)
├── sources/       (empty)
└── assets/        (empty)
```

…plus any domain-specific folders from Step 3.
