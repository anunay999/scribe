---
name: wiki-ingest
description: Use when the user shares a source (URL, gist, file path, paste, screenshot) they want indexed into the wiki. Reads the source, files it under sources/, updates or creates affected wiki pages with cross-links, and appends a log entry. Required before ingesting: WIKI.md must exist (run /wiki-bootstrap first).
---

# wiki-ingest

> One source can touch 10–15 wiki pages. That's the point.

## Preconditions

1. `WIKI.md` exists in the vault. If not: tell the user to run `/wiki-bootstrap` first; don't auto-bootstrap from inside ingest.
2. The source is identifiable: URL, file path, or pasted text. If none of those: ask "what should I ingest?" and stop.

## Process

### Step 1 — fetch and slug

- URL: fetch with `WebFetch` or `curl -sL`. If the URL is a github gist, prefer `curl -sL <raw-url>` for the markdown.
- File: read directly.
- Paste: trust the user's text.

Slug rule: `<short-kebab-case-title>`. Strip dates, source domain, "the", "a". Examples:
- "How LLMs build wikis — Karpathy" → `karpathy-llm-wiki`
- "PR #7116 chain resolution" → `pr-7116-chain-resolution`

If the source has a date the user wants tracked, prefix the slug: `2026-04-25-team-meeting`.

### Step 2 — write the raw

`sources/<slug>.md` with frontmatter:

```yaml
---
title: <human title>
type: source
url: <if known>
ingested: <YYYY-MM-DD>
tags: [<topical tags>]
---
```

Body:

```markdown
# Source: <title>

URL: <url>

## TL;DR

(2–4 sentences; the thing a future Claude skims)

## Key takeaways

- bullet
- bullet

## Direct quotes worth keeping

> ...

## Application to this wiki

(How this source should change existing pages — name them with [[wikilinks]].)

## Related

- [[<page-A>]]
- [[<page-B>]]
```

### Step 3 — propagate

Identify affected pages by reading the source's content and looking up [[index]]. For each affected page:

- **Existing page**: edit in place. Add a one-line note explaining the new evidence and link to the source. Append a `## History` entry: `- {{today}}: updated from [[sources/<slug>]] — <one-line summary>`.
- **Missing page**: create it. Use the standard frontmatter + body structure from `WIKI.md`. Link from at least one existing page so it's not orphaned.
- **Contradictions**: surface them. Add a `> [!warning]` callout on the contradicting page citing the source. Don't auto-resolve — let the user decide.

Be efficient: parallel `Read` on candidate pages first, then a single round of `Edit` calls.

### Step 4 — update index

Add the new source page to `index.md` under the `## Sources` section. Add any new entity/concept pages under their respective sections.

### Step 5 — append to log

```markdown
## [{{today}}] ingest | <Title> ([[sources/<slug>]])

Touched: [[<page-A>]], [[<page-B>]], [[<page-C>]]. New: [[<new-page>]] if any. <One-line key takeaway.>
```

### Step 6 — discuss

End-of-turn message to the user:

- One-sentence summary of what the source was about.
- 1–3 bullets of what changed in the wiki.
- One question that the source raised but didn't answer (drives the next ingest).

## Anti-patterns

- **Don't** dump the entire source into the raw page. Quote selectively. The source URL stays linked — readers can follow it.
- **Don't** create a new page for every entity mentioned. Threshold: a new page if the entity will be referenced from 3+ other pages, or if it has standalone properties worth recording.
- **Don't** silently overwrite a page. Either edit-with-history or create.
- **Don't** skip the log entry. The log is how future Claude knows what's recent.

## Edge cases

- **Image sources**: download to `assets/<slug>/`. Reference inline. Note that LLM passes can't render images and text in one pass — record the image's purpose in prose so the next session understands without rendering.
- **Paywalled URL**: tell the user. Don't fabricate content.
- **Already-ingested source** (URL already in `sources/`): show the existing page, ask whether to refresh or skip. Don't double-write.
