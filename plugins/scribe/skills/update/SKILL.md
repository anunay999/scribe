---
name: update
description: Use when a fact has changed and a specific wiki page (or set of pages) needs editing. Edits the page in place, propagates the change to linked pages that reference the same fact, appends a History entry, and logs the update. Avoids the wholesale "ingest" path when no new source is involved.
---

# update

> Use this when the change is *known* and *small*. For larger changes driven by a new source, use `/scribe-ingest`.

## When to use

- "PR #7116 just merged — update its status."
- "Phillips 66 followers in `infrastructure/databricks` is wrong, it's 217 not 27."
- "Rename project X to Y."
- "Mark project Z as done."

When **not** to use:

- New source dropped → `/scribe-ingest`.
- Question asked → `/scribe-query`.
- Health check → `/scribe-lint`.

## Process

### Step 1 — locate

Identify the target page(s):

- If the user named a page (e.g., `projects/chain-resolution`), open it.
- If the user described a fact, search `WIKI.md` and `index.md` for likely pages, then grep the body of those pages.

### Step 2 — edit

Apply the change as a focused `Edit` (or `Write` for a full rewrite, only when the user asks for one). Keep the rest of the page intact.

If the page has frontmatter `updated:`, bump it to today.
If the change implies a status flip (`active → done`), update both `status:` in frontmatter and the body.

### Step 3 — propagate

Find pages that mention the same fact. Heuristic:

1. Backlinks of the target page (pages that `[[link]]` to it).
2. Pages tagged with the same entity.
3. `index.md` entries about the target.

For each, decide:

- **Same fact, needs update** → edit it. Don't restate the canonical detail; link to the canonical page and update only what differs.
- **Now stale** → add `#stale` tag and a one-line note pointing at the canonical page.
- **Now contradicts** → resolve if obvious; otherwise add a `> [!warning]` callout citing the canonical page and surface it in the lint.

Update `index.md` if the change moves a project between Active / Planned / Completed sections.

### Step 4 — append history

On the canonical page:

```markdown
## History

- {{today}}: <one-line description of the change> — by user request
```

If a `## History` section already exists, append. Don't reorder; newest at the bottom (chronological forward) — easier to scan.

### Step 5 — log

```markdown
## [{{today}}] update | <page-slug> — <one-line summary>

Touched: [[page-A]], [[page-B]], [[page-C]].
```

### Step 6 — confirm

Brief end-of-turn:

- One sentence: what changed.
- List of pages touched.
- Anything you noticed but didn't change (offer follow-up).

## Anti-patterns

- **Don't** rewrite the whole page when a 1-line edit suffices. Edit in place.
- **Don't** silently update other pages that reference the changed fact. Either edit them with a History entry, or surface them as "I noticed [[page-X]] also mentions this — should I update it?"
- **Don't** delete a `## History` entry to "clean up." History is append-only.
- **Don't** skip the log entry. Future Claude needs to know what changed and why.
