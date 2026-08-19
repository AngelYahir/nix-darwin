{config, pkgs, lib, ...}:
{
    home.stateVersion = "25.05";
    fonts.fontconfig.enable = true;

    programs.zsh = {
        enable = true;
        dotDir = config.home.homeDirectory;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        
        # History configuration
        history = {
            size = 5000;
            save = 5000;
            ignoreDups = true;
            ignoreAllDups = true;
            ignoreSpace = true;
            share = true;
            extended = true;
        };
        
        # Key bindings
        defaultKeymap = "emacs";
        initContent = ''
            # Custom key bindings
            bindkey '^p' history-search-backward
            bindkey '^n' history-search-forward
            bindkey '^[w' kill-region
            
            # FZF configuration and styling
            source <(fzf --zsh)
            export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
              --color=fg:#cdd6f4,fg+:#d0d0d0,bg:#1e1e2e,bg+:#262626
              --color=hl:#f38ba8,hl+:#5fd7ff,info:#cba6f7,marker:#b4befe
              --color=prompt:#cba6f7,spinner:#f5e0dc,pointer:#f5e0dc,header:#f38ba8
              --color=border:#b4befe,label:#cdd6f4,query:#d9d9d9
              --border="rounded" --border-label="" --preview-window="border-bold" --padding="1"
              --margin="3" --prompt="󰄛  " --marker="> " --pointer="◆"
              --separator="─" --scrollbar="│" --layout="reverse" --info="right"'
            
            # Completion styling
            zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
            zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
            zstyle ':completion:*' menu no
            
            # Source catppuccin theme for syntax highlighting
            source ${config.home.homeDirectory}/.config/zsh/catppuccin.zsh
            
            # Source custom zsh configuration
            if [[ -f "${config.home.homeDirectory}/.config/zsh/.zshrc" ]]; then
                source "${config.home.homeDirectory}/.config/zsh/.zshrc"
            fi
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
        
        oh-my-zsh = {
            enable = true;
            plugins = [ 
                "git" 
                "macos" 
                "sudo" 
                "z"
                "aws"
                "kubectl"
                "kubectx"
                "command-not-found"
            ];
        };
    };

    home.sessionPath = [
        "${config.home.homeDirectory}/.cargo/bin"
    ];

    home.sessionVariables = {
        RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
        CARGO_HOME = "${config.home.homeDirectory}/.cargo";
        # Fuerza Apple Clang para evitar gcc de Nix como 'cc'
        CC  = "/usr/bin/clang";
        CXX = "/usr/bin/clang++";
    };

    # Starship prompt
    programs.starship.enable = true;

    home.packages = with pkgs; [
        # Home Manager command
        home-manager

        #devtools
        neovim
        git
        lazygit
        gitkraken
        vscode

        # Programming languages
        nodejs_22
        pnpm
        python314
        rustc
        go
        cargo
        lua
        luajitPackages.luarocks_bootstrap

        # Utilities
        btop
        htop
        fzf
        eza
        fastfetch
        ripgrep
        zsh-fzf-tab
        copilot-cli
        bitwarden-desktop
        raycast
        nowplaying-cli

        # Terminal emulators
        wezterm
        kitty
        starship
        yazi
        bat
        fd

        # Networking
        wget
        curl
        openssh
        postman
        insomnia

        # Database clients
        postgresql
        jq

        # Window management
        #yabai
        #skhd
        #sketchybar

        #Some shit
        pipes
        lolcat
        cowsay
	
	#Browser
	brave
    ];

    xdg.enable = true;
    home.activation.linkApplications = lib.hm.dag.entryAfter ["writeBoundary"] ''
        mkdir -p "$HOME/Applications/Home Manager"
        for app in "$HOME/.nix-profile/Applications/"*.app; do
        ln -sf "$app" "$HOME/Applications/Home Manager/"
        done
    '';

    # Symlink dotfiles to ~/.config
    home.file.".config/zsh".source = ../config/zsh;
    home.file.".config/nvim".source = ../config/nvim;
    home.file.".config/yazi".source = ../config/yazi;
    home.file.".config/wezterm".source = ../config/wezterm;
    home.file.".config/starship.toml".source = ../config/starship.toml;
    home.file.".config/skhd".source = ../config/skhd;
    home.file.".config/yabai".source = ../config/yabai;
    home.file.".config/cava".source = ../config/cava;
    home.file.".config/bat".source = ../config/bat;
    home.file.".config/btop".source = ../config/btop;
    home.file.".config/ghostty".source = ../config/ghostty;
    home.file.".config/fastfetch".source = ../config/fastfetch;
    home.file.".config/sketchybar".source = ../config/sketchybar;
    home.file.".config/eza".source = ../config/eza;
}
