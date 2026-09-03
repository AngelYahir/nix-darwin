{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  template = ./template;

  agent-project-init = pkgs.writeShellApplication {
    name = "agent-project-init";

    runtimeInputs = with pkgs; [
      git
      coreutils
      herdr
    ];

    text = ''
      set -euo pipefail

      if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
        :
      else
        root="$(pwd)"
      fi

      cd "$root"

      copy_if_missing() {
        src="$1"
        dst="$2"

        if [[ -e "$dst" ]]; then
          echo "skip: $dst"
          return
        fi

        cp -R --no-preserve=mode -- "$src" "$dst"
        echo "create: $dst"
      }

      echo "Initializing agent project at: $root"

      mkdir -p \
        .ai/tasks \
        .ai/decisions \
        .ai/handoffs \
        .ai/examples \
        .claude/skills/herdr \
        .agents/skills/herdr

      copy_if_missing "${template}/PROJECT.md" ".ai/PROJECT.md"
      copy_if_missing "${template}/STATE.md" ".ai/STATE.md"
      copy_if_missing "${template}/ROADMAP.md" ".ai/ROADMAP.md"
      copy_if_missing "${template}/HANDOFF.md" ".ai/handoffs/current.md"
      copy_if_missing "${template}/examples/TASK.md" ".ai/examples/TASK.md"
      copy_if_missing "${template}/CLAUDE.md" "CLAUDE.md"
      copy_if_missing "${template}/AGENTS.md" "AGENTS.md"
      copy_if_missing "${template}/skills/orchestrate" ".claude/skills/orchestrate"

      if [[ ! -e .claude/skills/herdr/SKILL.md || ! -e .agents/skills/herdr/SKILL.md ]]; then
        herdr_skill="$(mktemp)"
        trap 'rm -f "$herdr_skill"' EXIT
        ${lib.getExe herdr} --skill > "$herdr_skill"
        copy_if_missing "$herdr_skill" ".claude/skills/herdr/SKILL.md"
        copy_if_missing "$herdr_skill" ".agents/skills/herdr/SKILL.md"
      else
        echo "skip: .claude/skills/herdr/SKILL.md"
        echo "skip: .agents/skills/herdr/SKILL.md"
      fi

      echo "Done. Next: edit .ai/PROJECT.md"
    '';
  };
in
{
  home.packages = [ agent-project-init ];
}
