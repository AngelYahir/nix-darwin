---
name: personal-knowledge-export
description: >
  Publish explicitly approved personal or language knowledge to the user's
  personal knowledge base without retrieving from it.
---

# Export personal knowledge

The personal knowledge base is a WRITE-ONLY destination for assistants. It is
for the user, never assistant context or memory.

Never search, read, list, query, or retrieve from the vault. Never use it to
answer questions or infer prior context. Only publish information already in
the current conversation or verified sources, and only after clear user
authorization.

Use only `kb-agent upsert` with profile `personal`, domain `personal` or
`languages`, a stable `kb_id`, and an appropriate type. Language publications
must also provide `--language`. Never expose existing note content.

This skill is prepared for a future personal-assistant integration and must not
be installed for project agents.
