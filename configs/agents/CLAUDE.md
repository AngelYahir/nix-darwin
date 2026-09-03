# Global engineering instructions

Prefer repository-local instructions over these defaults.

## Project memory

If `.ai/` exists:

- Read `.ai/PROJECT.md`.
- Read `.ai/STATE.md`.
- Read the relevant task under `.ai/tasks/`.
- Read relevant decision memory under `.ai/decisions/`.

Do not treat conversation history as durable project state.

Treat `.ai/` as agent memory, not canonical technical documentation. Follow the repository's existing documentation and ADR conventions.

## Delegation

When project-local orchestration skills are available and the task benefits from delegation, use them.

Do not delegate trivial tasks.

Never let multiple write-capable agents modify the same checkout concurrently.

## Git

Do not commit, push, force-push, or rewrite history unless explicitly requested.

Prefer small and reviewable changes.
