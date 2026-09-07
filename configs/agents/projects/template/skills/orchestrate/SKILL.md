---
name: orchestrate
description: Coordinate delegated software work when independent subtasks or review justify multiple agents, or when the user requests delegation.
---

# Orchestrate development work

Work directly when delegation would add overhead without a concrete benefit. Otherwise choose the smallest useful set of workers based on the task and available capabilities. Codex suits complex implementation; Copilot suits bounded mechanical work, but neither is required by default. `--delegate` requests delegation, not a fixed roster; respect explicitly requested agents. If requested delegation is unavailable, report the blocker instead of silently substituting local work.

## Scope and context

Use relevant project instructions and context already available. Read missing task scope or architectural decisions as needed. Load only skills needed for the current phase; workers load those needed for their own work.

Give each worker a bounded objective, relevant paths, constraints, and acceptance criteria. Workers may not inherit conversation history. Use a task file under `.ai/tasks/` when a shared contract or continuation needs durable state; otherwise a concise prompt is enough. Avoid copying full histories, logs, or unrelated documentation.

Let the worker investigate its implementation; the orchestrator focuses on dependencies, decisions, review, and integration. Choose models and reasoning appropriate to complexity and risk, preserving user settings unless a change is requested. Do not reduce reasoning merely to compensate for oversized context.

## Execution

Use existing delegation tools. Load the local Herdr skill only when using Herdr; create or reuse panes only for participating workers. Verify prompt delivery and activity. Prefer completion notifications or bounded waits; inspect detailed logs when progress stalls or errors occur.

Never let concurrent writers share a checkout. Use isolated worktrees for concurrent implementation or when isolation otherwise matters. Assign explicit scope and checkout ownership. Workers must not modify another checkout, integrate their own branches, push, force-push, or rewrite shared history. The orchestrator owns integration; preserve unrelated changes and user authorization boundaries.

## Completion

Ask workers for changed files, validation results, remaining risks, and blockers. Inspect the actual diff and relevant evidence, not just summaries. Run the smallest relevant checks on the integrated result; avoid rerunning unchanged checks without a reason. Resolve remaining work locally or return it to the worker according to ownership and coordination cost.

Persist only useful decisions and continuation state in `.ai/`; keep canonical documentation in the repository's existing structure. At task or phase boundaries, preserve a short handoff before starting a fresh session or compacting a long one when needed.
