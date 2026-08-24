{ pkgs, ... }:

{ 
    programs.sketchybar = {
        enable = true;

        extraPackages = with pkgs; [
            jq
        ];

        configType = "lua";
        sbarLuaPackage = pkgs.sbarlua;

        service = {
            enable = true;
            errorLogFile = "/tmp/sketchybar.error.log";
            outLogFile = "/tmp/sketchybar.out.log";
        };

        config = {
            source = ./sketchybar;
            recursive = true; 
        };
    };
}