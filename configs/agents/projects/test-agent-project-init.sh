#!/usr/bin/env bash
set -euo pipefail

init="${1:-agent-project-init}"
test_root="$(mktemp -d)"
fallback_root="$(mktemp -d)"
trap 'rm -rf "$test_root" "$fallback_root"' EXIT

git -C "$test_root" init -q
mkdir -p "$test_root/nested"
cd "$test_root/nested"

"$init"

for path in \
  CLAUDE.md \
  AGENTS.md \
  .ai/PROJECT.md \
  .ai/STATE.md \
  .ai/ROADMAP.md \
  .ai/handoffs/current.md \
  .ai/examples/TASK.md \
  .claude/skills/orchestrate/SKILL.md \
  .claude/skills/knowledge-export/SKILL.md \
  .agents/skills/knowledge-export/SKILL.md \
  .claude/skills/herdr/SKILL.md \
  .agents/skills/herdr/SKILL.md; do
  test -e "$test_root/$path"
done
cmp -s "$test_root/.claude/skills/herdr/SKILL.md" "$test_root/.agents/skills/herdr/SKILL.md"
cmp -s "$test_root/.claude/skills/knowledge-export/SKILL.md" "$test_root/.agents/skills/knowledge-export/SKILL.md"

printf 'project-specific state\n' > "$test_root/.ai/STATE.md"
printf 'project-specific Claude skill\n' > "$test_root/.claude/skills/knowledge-export/SKILL.md"
printf 'project-specific Codex skill\n' > "$test_root/.agents/skills/knowledge-export/SKILL.md"
"$init"
test "$(cat "$test_root/.ai/STATE.md")" = "project-specific state"
test "$(cat "$test_root/.claude/skills/knowledge-export/SKILL.md")" = "project-specific Claude skill"
test "$(cat "$test_root/.agents/skills/knowledge-export/SKILL.md")" = "project-specific Codex skill"
test -z "$(find "$test_root" -mindepth 2 -type d -name .git -print -quit)"

cd "$fallback_root"
"$init"
test -e "$fallback_root/.ai/PROJECT.md"
test ! -e "$fallback_root/.git"

echo "agent-project-init test passed"
