{
    pkgs,
    username,
    hostname,
    ...
}:

{
    imports = [ 
            ./homebrew.nix
            ../configs/jankyborders.nix
            ../configs/aerospace.nix
            ../configs/fonts.nix
            ../configs/macos.nix
        ];

    nixpkgs.hostPlatform = "aarch64-darwin";
    system.primaryUser = username;
    networking.hostName = hostname;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    users.users.${username} = { home = "/Users/${username}"; };

    system.stateVersion = 7;
}