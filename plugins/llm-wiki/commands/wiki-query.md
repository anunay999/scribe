---
description: Answer a question from the wiki with citations; file non-trivial answers back as new pages.
---

Invoke the `llm-wiki:wiki-query` skill via the Skill tool with the user's question. Follow the skill's process: read index.md, drill into candidates, synthesize with [[wikilink]] citations, file back if non-trivial.

Question: $ARGUMENTS
