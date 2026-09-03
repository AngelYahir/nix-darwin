{
    inputs,
    username,
    ...
}:
{
    imports = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.catppuccin.homeModules.catppuccin  

        ./packages.nix
        ../configs/sops.nix
        ../configs/git.nix
        ../configs/zsh.nix
        ../configs/ghostty.nix
        ../configs/sketchybar.nix
        ../configs/starship.nix
        ../configs/fastfetch.nix
        ../configs/zellij.nix
        ../configs/obsidian.nix
        ../configs/zen.nix
        ../configs/yazi.nix
        ../configs/cava.nix
        ../configs/codex.nix
        ../configs/agents
        ../configs/assistants

        ../configs/wp.nix
    ];

    catppuccin = {
        enable = true;
        autoEnable = true;
        flavor = "mocha";
        accent = "mauve";
    };

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.file.".hushlogin".text = "";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
}
