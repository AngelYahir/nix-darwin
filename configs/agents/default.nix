{ inputs, lib, pkgs, ... }:

let
    context7Url = "https://mcp.context7.com/mcp";
    herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
    projectAgents = pkgs.writeShellApplication {
        name = "project-agents";
        runtimeInputs = [
            herdr
            pkgs.git
            pkgs.jq
            pkgs.coreutils
            pkgs.gnused
        ];
        text = builtins.readFile ./scripts/project-agents.sh;
    };
    skills = {
        ponytail = "${inputs.ponytail}/skills/ponytail";
        archify = "${inputs.archify}/archify";
        context7-mcp = "${inputs.context7}/skills/context7-mcp";
        thermo-nuclear-code-quality-review = "${inputs.cursor-plugins}/cursor-team-kit/skills/thermo-nuclear-code-quality-review";
        systematic-debugging = "${inputs.superpowers}/skills/systematic-debugging";
        verification-before-completion = "${inputs.superpowers}/skills/verification-before-completion";
        documentation = "${inputs.documentation}/skills/documentation";
        adr-authoring = "${inputs.agent-skills}/adr-authoring";
    };
in

{
    imports = [
        ./projects
    ];

    programs.claude-code = {
        enable = true;
        package = null;
        mcpServers.context7 = {
            type = "http";
            url = context7Url;
        };
    };

    home.packages = [ projectAgents ];

    # Codex Desktop owns the rest of config.toml, so preserve it and add only
    # the missing server through the CLI instead of replacing the whole file.
    home.activation.context7CodexMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! /opt/homebrew/bin/codex mcp get context7 >/dev/null 2>&1; then
            run /opt/homebrew/bin/codex mcp add context7 --url ${lib.escapeShellArg context7Url}
        fi
    '';

    home.file = {
        ".claude/CLAUDE.md".source = ./CLAUDE.md;

        ".config/herdr/config.toml" = {
            force = true;
            text = ''
                onboarding = false

                [ui.toast]
                delivery = "off"

                [session]
                resume_agents_on_restore = true

                [worktrees]
                directory = "~/.herdr/worktrees"
            '';
        };
    } // lib.listToAttrs (lib.concatMap (target:
        lib.mapAttrsToList (name: source: {
            name = "${target}/${name}";
            value = {
                force = true;
                inherit source;
                recursive = true;
            };
        }) skills
    ) [ ".claude/skills" ".agents/skills" ]);
}
