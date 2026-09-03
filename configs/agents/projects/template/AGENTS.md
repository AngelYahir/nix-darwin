# Agent instructions

Before non-trivial work, read:

- `.ai/PROJECT.md`
- `.ai/STATE.md`

If a task ID is provided, read `.ai/tasks/<task-id>.md` and treat it as the scope and acceptance criteria.

Do not modify unrelated code. Run the smallest relevant validation.

Treat `.ai/` as agent memory, not canonical technical documentation. Follow the repository's existing documentation and ADR conventions.

Report:

- Changed files
- Tests or checks executed
- Remaining risks
- Blockers

Do not merge, push, force-push, or rewrite shared history unless explicitly requested.

When working as a delegated worker, the orchestrator owns integration.
