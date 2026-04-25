---
name: capture
description: Use when the user wants Claude to scan the *recent conversation* for wiki-worthy content and propose what to save. Surfaces decisions, facts, code paths, gotchas, and links discovered during the session — then asks the user which ones to ingest. Less heavy than a full `ingest` (no fetching) and broader than `update` (no specific target).
---

# capture

> "We just had a useful conversation. Save the gold from it."

This skill bridges the gap between `ingest` (which needs an explicit source) and `update` (which needs a specific page). It scans the *current Claude conversation* for things worth filing, presents them as a checklist, and lets the user pick what lands.

## When to use

- After a long explanation or debugging session that produced new understanding.
- After Claude wrote a non-trivial answer with reasoning the user wants preserved.
- After the user shared a fact or constraint Claude should remember (e.g., "by the way, our prod warehouse ID is …").
- At the end of a working session, as a "wrap up the wiki" pass.

When **not** to use:

- The user has a specific source they want indexed → use `ingest`.
- The user has a specific fact to change → use `update`.
- Trivial Q&A that doesn't add to the wiki's body of knowledge.

## Process

### Step 1 — scan the conversation

Look back over the recent turns (this session). Extract candidates:

| Candidate type | What to look for |
|---|---|
| **Decision** | Phrases like "we'll do X because Y", "decided to", explicit tradeoff resolution |
| **Fact** | Concrete values, IDs, URLs, paths, version numbers stated as authoritative |
| **Gotcha** | "Watch out for…", "this fails if…", "tricky because…" |
| **Code path** | `path/to/file.py:N` references with surrounding context |
| **Concept** | A term used 3+ times that doesn't have a wiki page yet |
| **Source** | URLs the user shared but didn't explicitly ask to ingest |
| **Person/system** | New entities mentioned that should have pages |

Skip:

- Trivial back-and-forth (`/help`, "thanks", "ok")
- Things already in the wiki (cross-check `index.md`)
- Scratch/experimental code that didn't ship

### Step 2 — propose

Single chat output, structured as a checklist:

```markdown
## Capture — {{today}}

I scanned the last N turns. Candidates to file (pick which to save):

### Decisions (M)
1. [ ] **<one-line decision>** — would land in `decisions/<slug>.md` or as ## History on [[<existing-page>]]
2. [ ] ...

### Facts (M)
1. [ ] **<fact>** — would update [[<page>]] (currently says: `<old>`)
2. [ ] ...

### Gotchas (M)
1. [ ] **<gotcha>** — would land in [[patterns/<slug>]] (new)
2. [ ] ...

### New concepts/systems (M)
1. [ ] **"X"** — referenced N times this session, no wiki page yet. Suggest [[domains/x]] or [[concepts/x]].

### Sources mentioned but not ingested (M)
1. [ ] **<url>** — would run `/scribe-ingest <url>` to index it.

Reply with the numbers to save (e.g. "decisions 1,2; gotchas 1; concepts 1") or `all`. Reply `none` to skip.
```

Be conservative — better to surface 5 high-quality candidates than 30 noisy ones.

### Step 3 — apply selected

For each item the user picks:

- **Decision** → if a relevant page exists, append `## History` + a `## Decision: …` section. Otherwise create `decisions/<slug>.md` with the decision + reasoning.
- **Fact** → invoke the `update` skill flow (locate, edit, propagate, history).
- **Gotcha** → invoke the `ingest` skill flow with a synthetic source (the conversation excerpt) saved as `sources/conversation-{{today}}-<slug>.md`.
- **Concept** → create the page; link from at least one existing page; update `index.md`.
- **Source** → invoke the `ingest` skill flow on the URL.

### Step 4 — log

```markdown
## [{{today}}] capture | <one-line summary>

Saved: <count> decisions, <count> facts, <count> gotchas, <count> concepts, <count> sources.
Touched: [[page-A]], [[page-B]].
```

### Step 5 — confirm

End-of-turn:

- One sentence: how many items landed where.
- One question if anything was ambiguous.

## Also update auto-memory

Scribe and Claude Code's auto-memory (`~/.claude/projects/<project>/memory/`) are complementary:

- **Auto-memory** = small, preloaded into every session. Hard rules, user preferences, pointers to where things live.
- **Scribe wiki** = large, on-demand, deeply linked. The body of knowledge.

When `capture` saves something **interesting and important**, also propose adding a one-line auto-memory pointer:

| What was captured | Memory file to add |
|---|---|
| New feature, app, or service the user is building or shipped | `project_<slug>.md` |
| Specific decision with durable consequences (architecture, naming, deprecation) | `project_<slug>.md` or `feedback_<slug>.md` |
| New convention or rule the user stated | `feedback_<slug>.md` |
| New external system, vault, or canonical reference path | `reference_<slug>.md` |

Memory entries are one-liners pointing at the wiki (`See [[wiki-page]] for details`). The body lives in scribe.

Skip memory for ordinary facts, gotchas, code paths — those belong in scribe alone. Bar: "would a future session need to know this exists before it asks?"

## Anti-patterns

- **Don't** save everything — that's how wikis get noisy and lose signal.
- **Don't** save without proposing first. The user picks.
- **Don't** treat every URL as a source — only ones the user discussed in depth.
- **Don't** invent decisions from "Claude said X". Decisions are things the user agreed to.
- **Don't** create a page for every term the user said once.

## Cadence

Suggested usage: once at the end of a working session, or after any conversation that ran > ~30 minutes on a single topic. Combine with `/scribe-lint` once a week.

## Related to other skills

- `ingest` — pointed at a specific source.
- `update` — pointed at a specific fact.
- `query` — answer a question; files synthesis pages on its own when non-trivial.
- `lint` — health check, no new content.
- `capture` — extracts wiki-worthy content from the conversation itself.
