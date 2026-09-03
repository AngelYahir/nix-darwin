---
name: knowledge-export
description: >
  Publish durable engineering knowledge to the user's personal knowledge base
  when the user explicitly asks to document or publish finalized knowledge.
---

# Export engineering knowledge

The personal knowledge base is a WRITE-ONLY destination for agents. It is for
the user, never project context or agent memory.

Never search, read, list, query, or otherwise retrieve from the vault. Never
use it to answer questions, infer project state, rebuild `.ai/`, or replace the
repository's canonical documentation and ADRs. Use only `kb-agent upsert`; no
other process or filesystem access to the vault is permitted by this workflow.

Publish only after a clear user instruction such as "documenta esto",
"guárdalo en mi knowledge base", "actualiza mi Obsidian", or "este cambio ya
es definitivo, documenta lo importante". You may suggest worthwhile topics,
but wait for authorization before writing.

Use only information already present in the current repository, task,
conversation, agent context, or verified documentation. Curate durable,
reusable architecture, decisions, patterns, lessons, incidents, runbooks,
references, or SDK knowledge. Do not publish routine commits, task status,
TODOs, logs, transient debugging, test output, or trivial changes.

When orchestrating, let workers report candidates and have the orchestrator
curate the final note. A worker may publish only when the user directly asked
that worker to publish a specific item.

Use vault alias `knowledge-base` by default. If the user explicitly asks for
Second Brain instead, use `second-brain`. Never invent or pass filesystem paths.

Write the proposed body to a temporary file or stdin, then run:

```sh
kb-agent upsert \
  --vault knowledge-base \
  --profile engineering \
  --project-auto \
  --id STABLE_KB_ID \
  --title "TITLE" \
  --type TYPE \
  --file NOTE_FILE
```

Use a stable `kb_id`. Summarize canonical repository docs or ADRs and refer to
them; do not copy them wholesale. The only successful output is publication
metadata such as `published: ID (vault: knowledge-base)` or
`updated: ID (vault: second-brain)`, never prior note content.

This is an architectural boundary, not a claim that same-user macOS processes
are technically unable to open the vault.
