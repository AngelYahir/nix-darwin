{
    username,
    ...
}:
{
    imports = [ 
        ./packages.nix
        ../configs/git.nix
        ../configs/zsh.nix
        ../configs/ghostty.nix
        ../configs/sketchybar.nix
        ../configs/starship.nix
    ];

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
}