{
    username,
    ...
}:

{
    nix-homebrew = {
        enable = true;
        user = username;
        enableRosetta = true;

        autoMigrate = true; 
    };

    homebrew = {
        enable = true;
        
        casks = [
            "zen"
            "arc"
            "visual-studio-code"
            "datagrip"
            "raycast"
            "ghostty"
            "onlyoffice"
            "sf-symbols"
        ];

        onActivation = {
            autoUpdate = true;
            upgrade = true;

            cleanup = "none";
        };
    };
}