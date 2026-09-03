{ config, inputs, lib, ... }:

let
    context7Url = "https://mcp.context7.com/mcp";
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

    # Codex Desktop owns the rest of config.toml, so preserve it and add only
    # the missing server through the CLI instead of replacing the whole file.
    home.activation.context7CodexMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! ${lib.getExe config.programs.codex.package} mcp get context7 >/dev/null 2>&1; then
            run ${lib.getExe config.programs.codex.package} mcp add context7 --url ${lib.escapeShellArg context7Url}
        fi
    '';

    home.file = {
        ".claude/CLAUDE.md".source = ./CLAUDE.md;

        ".claude/skills/ponytail" = {
            force = true;
            source = "${inputs.ponytail}/skills/ponytail";
            recursive = true;
        };
        ".claude/skills/archify" = {
            force = true;
            source = "${inputs.archify}/archify";
            recursive = true;
        };
        ".agents/skills/ponytail" = {
            force = true;
            source = "${inputs.ponytail}/skills/ponytail";
            recursive = true;
        };
        ".agents/skills/archify" = {
            force = true;
            source = "${inputs.archify}/archify";
            recursive = true;
        };
        ".claude/skills/context7-mcp" = {
            force = true;
            source = "${inputs.context7}/skills/context7-mcp";
            recursive = true;
        };
        ".agents/skills/context7-mcp" = {
            force = true;
            source = "${inputs.context7}/skills/context7-mcp";
            recursive = true;
        };
        ".claude/skills/thermo-nuclear-code-quality-review" = {
            force = true;
            source = "${inputs.cursor-plugins}/cursor-team-kit/skills/thermo-nuclear-code-quality-review";
            recursive = true;
        };
        ".agents/skills/thermo-nuclear-code-quality-review" = {
            force = true;
            source = "${inputs.cursor-plugins}/cursor-team-kit/skills/thermo-nuclear-code-quality-review";
            recursive = true;
        };
        ".claude/skills/systematic-debugging" = {
            force = true;
            source = "${inputs.superpowers}/skills/systematic-debugging";
            recursive = true;
        };
        ".agents/skills/systematic-debugging" = {
            force = true;
            source = "${inputs.superpowers}/skills/systematic-debugging";
            recursive = true;
        };
        ".claude/skills/verification-before-completion" = {
            force = true;
            source = "${inputs.superpowers}/skills/verification-before-completion";
            recursive = true;
        };
        ".agents/skills/verification-before-completion" = {
            force = true;
            source = "${inputs.superpowers}/skills/verification-before-completion";
            recursive = true;
        };
        ".claude/skills/documentation" = {
            force = true;
            source = "${inputs.documentation}/skills/documentation";
            recursive = true;
        };
        ".agents/skills/documentation" = {
            force = true;
            source = "${inputs.documentation}/skills/documentation";
            recursive = true;
        };
        ".claude/skills/adr-authoring" = {
            force = true;
            source = "${inputs.agent-skills}/adr-authoring";
            recursive = true;
        };
        ".agents/skills/adr-authoring" = {
            force = true;
            source = "${inputs.agent-skills}/adr-authoring";
            recursive = true;
        };

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
    };
}
