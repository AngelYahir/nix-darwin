# Global engineering instructions

Prefer repository-local instructions and preserve unrelated changes.

Work directly when coordination would add more overhead than value. Use the project-local `orchestrate` skill when delegation or multi-agent coordination is useful or requested; choose workers by the task, not a fixed roster.

Load skills, documentation, and tools only when they help the current task. Read relevant project memory once and revisit it when it changes; avoid repeating context already available. Use `.ai/` for durable task state when needed, not duplicate technical documentation.

Keep searches and tool output focused. Delegate bounded work with enough context to act independently; avoid repeating the worker's investigation. Prefer completion notifications or bounded waits over frequent status polling.

Preserve the user's model and reasoning settings. Reduce redundant context and coordination before trading away reasoning quality.

Inspect changed code and run the smallest relevant validation before completion or integration. Repeat checks when changes or unresolved risks warrant it. Report results, limitations, and blockers concisely.

Never let concurrent writers share a checkout. Delegated workers stay within their assigned scope and checkout; the orchestrator owns integration. Do not commit, merge, push, force-push, or rewrite shared history unless authorized.
