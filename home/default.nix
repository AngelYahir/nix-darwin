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
        ../configs/jankyborders.nix
        ../configs/aerospace.nix
        ../configs/sketchybar.nix
    ];

    home.username = username;
    home.homeDirectory = "/Users/${username}";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
}