# Project instructions

Before non-trivial work, read `.ai/PROJECT.md` and `.ai/STATE.md`.

If a task ID is provided, read `.ai/tasks/<task-id>.md` and treat it as the scope and acceptance criteria. Review the repository's canonical ADRs and relevant memory in `.ai/decisions/` before architectural changes.

Use the `orchestrate` skill for complex multi-agent work. Keep small tasks local when delegation costs more than the work.

Keep `.ai/STATE.md` brief and current. Treat `.ai/` as agent memory, not canonical technical documentation. Follow the repository's existing documentation and ADR conventions; if none exists, prefer `docs/adr/` for human-facing ADRs and use `.ai/decisions/` only for compact orchestration context or pointers. Never duplicate the same decision.

Workers must not integrate their own branches. The orchestrator owns review and integration.
