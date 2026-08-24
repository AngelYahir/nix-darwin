{ ... }:

{
    programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        interactiveShellInit = ''
            export NVM_DIR="$HOME/.nvm"

            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        '';

        # Shell aliases
        shellAliases = {
            ls = "ls --color";
            vim = "nvim";
            c = "clear";
            lc = "eza -a -l --icons --no-time --no-user --color=always";
            h = "z ~";
            # FZF aliases
            cdf = "cd \"$(fd -t d | fzf --preview \"eza --icons --long --level=3 --color=always {}\")\";";
            vf = "fzf -m --preview=\"bat --color=always --style=numbers,grid {}\" | xargs -r nvim";
        };
    };

    programs.starship = {
        enable = true;
        enableZshIntegration = true;
    };

    programs.fzf = {
        enable = true;
        enableZshIntegration = true;
    };

    programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
    };
}