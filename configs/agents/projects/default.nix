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

      update_skill() {
        src="$1"
        dst="$2"

        mkdir -p "$dst"
        cp -R --no-preserve=mode -- "$src"/. "$dst"
        echo "update: $dst"
      }

      update_file() {
        cp --no-preserve=mode -- "$1" "$2"
        echo "update: $2"
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
      update_file "${template}/CLAUDE.md" "CLAUDE.md"
      update_file "${template}/AGENTS.md" "AGENTS.md"
      update_skill "${template}/skills/orchestrate" ".claude/skills/orchestrate"
      update_skill "${template}/skills/knowledge-export" ".claude/skills/knowledge-export"
      update_skill "${template}/skills/knowledge-export" ".agents/skills/knowledge-export"

      herdr_skill="$(mktemp)"
      trap 'rm -f "$herdr_skill"' EXIT
      ${lib.getExe herdr} --skill > "$herdr_skill"
      update_file "$herdr_skill" ".claude/skills/herdr/SKILL.md"
      update_file "$herdr_skill" ".agents/skills/herdr/SKILL.md"

      echo "Done. Next: edit .ai/PROJECT.md"
    '';
  };
in
{
  home.packages = [ agent-project-init ];
}
