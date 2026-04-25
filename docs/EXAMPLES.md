# Examples

End-to-end transcripts of the five workflows.

---

## Bootstrap

```text
> /wiki-bootstrap

Claude: I'll set up your vault. Three quick questions:
  1. Vault root? (default: ~/Documents/obsidian/claude/)
  2. Domain? (work / research / personal / book / mixed)
  3. Top topics? (2–4 short)

> default. work. data pipelines, frontend, infra.

Claude: Bootstrapping ~/Documents/obsidian/claude/ for work — topics:
data pipelines, frontend, infra.

  ✓ Created folders: projects/, people/, infrastructure/, patterns/,
    domains/, prs/, sources/, assets/
  ✓ Wrote WIKI.md (schema)
  ✓ Wrote index.md (catalog)
  ✓ Wrote log.md (event journal, first entry)
  ✓ Wired memory pointer in
    ~/.claude/projects/<this-project>/memory/MEMORY.md

Open ~/Documents/obsidian/claude/index.md in Obsidian to see the graph.
Try next:
  /wiki-ingest <url>           # add a source
  /wiki-query <question>       # ask the wiki
  /wiki-lint                   # health check
```

---

## Ingest a gist

```text
> /wiki-ingest https://gist.githubusercontent.com/karpathy/.../llm-wiki.md

Claude: Reading the source…
  ✓ Wrote sources/karpathy-llm-wiki.md (TL;DR + key takeaways + quotes)
  ✓ Created patterns/memory-system.md (how the wiki coexists with auto-memory)
  ✓ Created patterns/wiki-workflow.md (ingest/query/lint flow)
  ✓ Updated index.md (added Sources + Patterns sections)
  ✓ Appended to log.md

The source describes a three-layer pattern (raw / wiki / schema) where
the LLM owns wiki maintenance. I created two pattern pages to anchor
how we'll apply it. Open question for next ingest: do you want a
domain-specific overlay (research / personal / book) or stick with the
work-default folders?
```

---

## Query

```text
> /wiki-query how does our sync layer handle retries?

Claude: Reads index.md, then domains/meteor.md, projects/entity-scoped-sync.md,
references/sync-tuning.md.

The Meteor → MC sync worker → Universe pipeline handles retries at three
layers:

  - Meteor (CRM-side) — bulk-API cursor state lives in Redis; failed
    fetches retry with exponential backoff. ([[domains/meteor]])
  - MC sync worker (BullMQ) — job-level retry budget, with retry reuse
    so a re-run continues from prior progress instead of restarting from
    cursor zero. ([[projects/entity-scoped-sync]])
  - Universe writer — Postgres batch writes are idempotent because
    `_make_entity_id` is deterministic, so a retried batch overwrites
    the same rows. ([[patterns/data-flow-meteor-to-universe]])

Two specifics aren't in the wiki yet — the exact retry budget number and
the cancel poll interval. Ingest an updated runbook? They live in
references/sync-tuning.md as TODOs.

I didn't file this answer back as a synthesis page — it touched 3 pages
and was a fact lookup. Let me know if you want it filed for next time.
```

---

## Update

```text
> /wiki-update mark project chain-resolution as done — PR #7116 just merged.

Claude:
  ✓ Edited projects/chain-resolution.md
    - frontmatter status: active → done
    - frontmatter updated: 2026-04-25 → 2026-04-30
    - body status note added
    - appended ## History entry
  ✓ Edited prs/pr-7116-chain-resolution.md
    - status: open → merged
    - appended ## History
  ✓ Moved [[projects/chain-resolution]] from "Active" to "Completed" in index.md
  ✓ Appended to log.md

Touched 3 files. I noticed [[domains/launchpad]] still says "active work:
chain-resolution" — should I move that to a "Recently shipped" section?
```

---

## Lint

```text
> /wiki-lint

Claude: Health check — 2026-05-01

### Orphan pages (2)
- [[infrastructure/ai-search]] — no inbound links. Suggest linking from
  [[domains/mission-control]] (search uses it).
- [[references/sync-tuning]] — only linked from log.md. Suggest linking
  from [[patterns/data-flow-meteor-to-universe]].

### Undocumented concepts (1)
- "Universe" mentioned in 7 pages but no page exists. Suggest creating
  domains/universe.md.

### Stale #active (1)
- [[projects/sync-observability]] — status: active, updated 47 days ago.
  Mark #stale or refresh?

### Missing cross-references (3)
- [[domains/cosmos]] mentions "Tool Hub" without linking
  [[infrastructure/cosmos-tool-hub]] (which exists).
- [[projects/intent-signals]] mentions "CDF" without linking
  [[concepts/change-data-feed]] (which exists).
- [[domains/meteor]] mentions "Attio" without linking
  [[projects/attio-missing-fields]] (which exists).

### Suggested follow-ups
- "What does the writeback path look like end-to-end?" — would create a
  useful synthesis page across [[projects/meteor-writeback]],
  [[patterns/data-flow-meteor-to-universe]], [[domains/meteor]].

Want me to apply any of these? Reply with section names or `all`.

> orphans, missing cross-references.

Claude: Applied 5 fixes. Ran /wiki-update on each affected page,
appended History entries, logged.
```
