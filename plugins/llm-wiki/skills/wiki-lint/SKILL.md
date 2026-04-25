---
name: wiki-lint
description: Use when the user asks to health-check the wiki, or after a stretch of ingests. Finds orphan pages, contradictions, stale claims, undocumented concepts mentioned across multiple pages, missing cross-references, and `#active` projects with no recent activity. Reports actionable findings; does not auto-fix without confirmation.
---

# wiki-lint

> Lint surfaces problems. The user decides what to fix.

## What it checks

For each check, output a section with the finding and a recommended action.

### 1. Orphan pages

Pages that *no other page* links to.

```bash
# Pseudocode
for page in <vault>/**/*.md:
  if no other .md file contains [[page-title]]:
    report
```

Exclude `WIKI.md`, `index.md`, `log.md` — these are roots.

### 2. Concepts mentioned but undocumented

Strings that appear in 3+ pages but have no page of their own. Heuristic: capitalized noun phrases inside body text that aren't already wikilinks.

### 3. Contradictions

Pages that make conflicting claims about the same entity. Detection: read pairs of pages tagged with the same entity; flag where `(field, value1)` differs from `(field, value2)` without a `## History` entry explaining the change.

### 4. Stale `#active`

Pages with `status: active` (in frontmatter) whose `updated:` field is more than 30 days ago, OR whose newest `## History` line is older than 30 days.

### 5. Missing cross-references

Pages that mention an entity name *without* wikilinking it, where a page for that entity exists.

### 6. Index drift

Pages on disk not listed in `index.md`, or `index.md` entries pointing to deleted pages.

### 7. Log drift

Recent file edits with no corresponding `log.md` entry. Heuristic: `git log --since=<last-lint>` (if vault is a git repo) ∩ `log.md` entries.

## Process

### Step 1 — gather

Read `WIKI.md`, `index.md`, `log.md`, and walk the vault for `*.md`. Build:

- set of all page titles
- map: page → outbound wikilinks
- map: page → inbound wikilinks (reverse)
- map: page → frontmatter fields
- map: page → `## History` last entry date

### Step 2 — run each check

For each of the seven checks, produce findings.

### Step 3 — report

Single chat output, sectioned:

```markdown
## Wiki lint — {{today}}

### Orphan pages (N)
- [[page-title]] — suggest linking from [[likely-parent]]
- ...

### Undocumented concepts (N)
- "Concept Name" mentioned in [[a]], [[b]], [[c]] — suggest creating concepts/concept-name.md
- ...

### Contradictions (N)
- [[page-A]] says X; [[page-B]] says Y. No History entry resolves it.
- ...

### Stale #active (N)
- [[project-X]] — last updated 45 days ago. Mark #stale or refresh?
- ...

### Missing cross-references (N)
- [[page-A]] mentions "Foo" but doesn't link to [[domains/foo]].
- ...

### Index drift (N)
- [[page-X]] exists on disk but not in index.md
- ...

### Log drift (N)
- [[page-Y]] edited 3 days ago, no log entry.
- ...

### Suggested follow-up questions

- "How does X relate to Y?" — would create a useful synthesis page.
- ...
```

### Step 4 — offer to fix

Ask: "Want me to apply any of these? Reply with the section names or `all`."

Only auto-fix what the user names. Per [[patterns/no-branch-switching]]-style discipline: nothing destructive without explicit consent.

## Anti-patterns

- **Don't** report empty sections. If no orphans, omit the section.
- **Don't** auto-create stub pages for every undocumented concept. Surface, ask.
- **Don't** invent contradictions that aren't there — be conservative on the contradiction check.
- **Don't** suggest deleting orphan pages without checking if they're sources or recently created.

## Cadence

Suggested: once a week, or after every 5–10 ingests. The plugin can hint via the log: if `log.md` has 10+ entries since the last `lint`, suggest one.
