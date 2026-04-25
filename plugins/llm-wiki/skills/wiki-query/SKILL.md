---
name: wiki-query
description: Use when the user asks a question that should be answered from the wiki rather than re-derived. Reads index.md first, drills into relevant pages, synthesizes an answer with [[wikilink]] citations, and files non-trivial answers back into the wiki as new pages so exploration compounds.
---

# wiki-query

> Good answers don't disappear into chat history — they become wiki pages.

## When to use

- User asks a factual question about anything previously ingested.
- User asks for a synthesis ("compare X and Y", "summarize state of Z").
- User asks for a recommendation grounded in their own context ("what should I do about A?").

When **not** to use:

- The question is fully answered by reading code/files in the user's working directory — use direct tools.
- The question is a fresh research topic with no existing coverage in the wiki — use general web/search and *then* offer `/wiki-ingest` for the result.

## Process

### Step 1 — read the index

```
Read <vault_root>/index.md
```

Skim to find candidate pages. Don't read every page — pick by section heading and one-line summary.

### Step 2 — read the candidate pages

Parallel `Read` on the 3–8 candidates. For each, extract the 2–4 sentences relevant to the question.

### Step 3 — synthesize

Write the answer in the chat with:

- Clear lead sentence answering the question.
- Citations as `[[wikilinks]]` to the pages used. *Every non-trivial claim* gets a citation.
- If the wiki has gaps for the question, say so explicitly and offer to web-search → ingest.
- If pages contradict, surface the contradiction with both citations. Recommend a `/wiki-lint` follow-up.

### Step 4 — file the answer back (when the answer is non-trivial)

Heuristics for "file it":

- **Comparison or table** → new `concepts/<slug>.md` or `patterns/<slug>.md`.
- **Recommendation with reasoning** → new `decisions/<slug>.md` (create the folder if missing).
- **Synthesis across 4+ pages** → new page summarizing the synthesis with backlinks to all sources.
- **Just a fact lookup** → no new page needed.

When filing:

- Use standard frontmatter from `WIKI.md`.
- Link from each source page back to the new synthesis page.
- Update `index.md`.
- Append `## [{{today}}] query | <slug>` to `log.md`.

### Step 5 — confirm

End-of-turn:

- One-sentence answer recap.
- Note if a new page was filed and where.
- One follow-up question the wiki suggests.

## Examples

### Example 1 — fact lookup, no new page

User: "What port does Cosmos run on?"

Claude:
- Read [[index]] → finds `domains/cosmos`.
- Read `domains/cosmos.md`.
- Answers: "Cosmos API runs on port 8090. ([[domains/cosmos]])."
- No new page filed; trivial fact.

### Example 2 — synthesis, files a new page

User: "Compare our Salesforce and HubSpot adapters."

Claude:
- Read [[index]] → finds `projects/sf-bulk-api`, mentions of HubSpot in `domains/meteor`.
- Read both.
- Synthesizes a comparison table.
- Files `concepts/sf-vs-hubspot-adapter-comparison.md` with the table.
- Links from both source pages.
- Appends to log.
- Answers in chat with the table inline + a pointer to the new page for next time.

## Anti-patterns

- **Don't** quote the wiki verbatim if the user didn't ask for a copy. Synthesize.
- **Don't** invent links. If a page would be useful but doesn't exist, name it as a gap and offer to create it via `/wiki-ingest` or directly.
- **Don't** file every answer as a new page. Trivial lookups stay in chat.
