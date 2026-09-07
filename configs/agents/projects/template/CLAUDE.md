# Project instructions

Before non-trivial work, read `.ai/PROJECT.md` and `.ai/STATE.md` if present and not already in context. If a task ID is provided, read `.ai/tasks/<task-id>.md` for scope and acceptance criteria. Read relevant ADRs before architectural changes.

Implement directly unless delegation offers a concrete benefit or the user requests it. Use `orchestrate` for coordination when needed; load only skills relevant to the current work.

Preserve unrelated changes. Inspect changed code and run the smallest relevant validation; report changed files, checks, remaining risks, and blockers. Delegated workers stay in their assigned checkout; the orchestrator owns integration.

Update `.ai/STATE.md` when there is useful state to preserve for continuation or handoff. Keep it brief. Treat `.ai/` as agent memory; keep canonical documentation and ADRs in the repository's existing structure without duplicating them.
