# Agent instructions

Before non-trivial work, read these if present and not already in context:

- `.ai/PROJECT.md`
- `.ai/STATE.md`

If a task ID is provided, read `.ai/tasks/<task-id>.md` and treat it as the scope and acceptance criteria.

Work directly unless delegation has a concrete benefit or is requested. Load only skills and references needed for the current work. Keep searches and tool output focused; preserve model and reasoning settings.

Do not modify unrelated code. Run the smallest relevant validation; repeat it only after relevant changes or unresolved failures.

Treat `.ai/` as agent memory, not canonical technical documentation. Follow the repository's existing documentation and ADR conventions.

Report:

- Changed files
- Tests or checks executed
- Remaining risks
- Blockers

Do not merge, push, force-push, or rewrite shared history unless explicitly requested.

When working as a delegated worker, the orchestrator owns integration.
