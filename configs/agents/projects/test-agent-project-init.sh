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

mkdir "$test_root/initial"
cp "$test_root/CLAUDE.md" "$test_root/initial/CLAUDE.md"
cp "$test_root/AGENTS.md" "$test_root/initial/AGENTS.md"
cp "$test_root/.claude/skills/orchestrate/SKILL.md" "$test_root/initial/orchestrate.md"
cp "$test_root/.claude/skills/knowledge-export/SKILL.md" "$test_root/initial/knowledge-export.md"
cp "$test_root/.claude/skills/herdr/SKILL.md" "$test_root/initial/herdr.md"
printf 'project-specific state\n' > "$test_root/.ai/STATE.md"
printf 'outdated Claude instructions\n' > "$test_root/CLAUDE.md"
printf 'outdated agent instructions\n' > "$test_root/AGENTS.md"
printf 'outdated orchestrate skill\n' > "$test_root/.claude/skills/orchestrate/SKILL.md"
printf 'project-specific Claude skill\n' > "$test_root/.claude/skills/knowledge-export/SKILL.md"
printf 'project-specific Codex skill\n' > "$test_root/.agents/skills/knowledge-export/SKILL.md"
printf 'outdated Claude Herdr skill\n' > "$test_root/.claude/skills/herdr/SKILL.md"
printf 'outdated Codex Herdr skill\n' > "$test_root/.agents/skills/herdr/SKILL.md"
"$init"
test "$(cat "$test_root/.ai/STATE.md")" = "project-specific state"
cmp -s "$test_root/initial/CLAUDE.md" "$test_root/CLAUDE.md"
cmp -s "$test_root/initial/AGENTS.md" "$test_root/AGENTS.md"
cmp -s "$test_root/initial/orchestrate.md" "$test_root/.claude/skills/orchestrate/SKILL.md"
cmp -s "$test_root/initial/knowledge-export.md" "$test_root/.claude/skills/knowledge-export/SKILL.md"
cmp -s "$test_root/initial/knowledge-export.md" "$test_root/.agents/skills/knowledge-export/SKILL.md"
cmp -s "$test_root/initial/herdr.md" "$test_root/.claude/skills/herdr/SKILL.md"
cmp -s "$test_root/initial/herdr.md" "$test_root/.agents/skills/herdr/SKILL.md"
test -z "$(find "$test_root" -mindepth 2 -type d -name .git -print -quit)"

cd "$fallback_root"
"$init"
test -e "$fallback_root/.ai/PROJECT.md"
test ! -e "$fallback_root/.git"

echo "agent-project-init test passed"
