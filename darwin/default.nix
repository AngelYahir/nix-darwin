{
    pkgs,
    username,
    hostname,
    ...
}:

{
    imports = [ ./homebrew.nix ];

    nixpkgs.hostPlatform = "aarch64-darwin";
    system.primaryUser = username;
    networking.hostName = hostname;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    users.users.${username} = { home = "/Users/${username}"; };

    system.defaults = {
        dock = {
            autohide = true;
            magnification = true;
            show-recents = false;
            tilesize = 48;
        };

        finder = {
            AppleShowAllFiles = true;
            FXPreferredViewStyle = "clmv";
        };

    };
    system.stateVersion = 7;
}