---
name: orchestrate
description: >
  Orchestrate complex software work across Claude, Codex and Copilot using
  Herdr, persistent project state and isolated Git worktrees. Use for large
  multi-step tasks, delegation, parallelizable work, session continuation and
  cross-agent review.
---

# Orchestrate development work

Claude is the primary orchestrator. Claude owns reasoning, architecture, planning, task decomposition, worker selection, delegation, review, integration, and persistent project state.

Use Codex for complex implementation, refactors, deep repository analysis, code review, complex tests, and execution tracing. Use Copilot for bounded changes, scaffolding, repetitive edits, simple tests, and mechanical work.

Keep architectural decisions, planning, integration, cross-task reasoning, and tasks cheaper to do directly with Claude.

## Establish context

Before non-trivial work:

1. Read `.ai/PROJECT.md`.
2. Read `.ai/STATE.md`.
3. Read the relevant file in `.ai/tasks/`.
4. Read canonical ADRs and relevant decision memory in `.ai/decisions/`.

Never use conversation history as the only source of truth. Keep `.ai/` as agent memory: update `.ai/STATE.md` with current state, `.ai/decisions/` with compact orchestration context or pointers, and `.ai/tasks/` with task details. Keep canonical technical documentation and ADRs in the repository's existing documentation structure; if none exists, prefer `docs/adr/` for human-facing ADRs. Never duplicate the same decision.

## Decide whether to delegate

Delegate when work is substantial, parallelizable, benefits from independent review, or must continue across sessions. Do not delegate trivial tasks or work whose coordination cost exceeds its implementation cost.

Use the project-local Herdr skill for the installed version's commands.

## Isolate every writer

Never allow two write-capable agents to modify the same checkout concurrently.

For delegated work with writes:

1. Create or update the persistent task file.
2. Create branch `agent/<worker>/<task-id>`.
3. Create an isolated Git worktree under `~/.herdr/worktrees`.
4. Start the worker inside that worktree.
5. Give the worker the task file as its source of truth.
6. Wait for the result.
7. Review the diff.
8. Run the relevant validations.
9. Integrate only after review passes.

Do not create nested Git repositories. Claude owns the primary checkout and integration.

Workers must not merge into the primary branch, push, force-push, rewrite shared history, or modify another worktree.

## Complete the task

Review worker output against the task acceptance criteria, record validation and remaining risks in the task file, and update `.ai/STATE.md` without turning it into a historical log.
