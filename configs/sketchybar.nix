{ pkgs, ... }:

let
    # nixpkgs still ships 1.2.1, whose direct MediaRemote access no longer works
    # reliably on recent macOS releases. 2.1.0 includes the helper used on
    # Sequoia/Tahoe, including browser sessions such as YouTube.
    nowplaying-cli = pkgs.nowplaying-cli.overrideAttrs (_: {
        version = "2.1.0";

        src = pkgs.fetchFromGitHub {
            owner = "kirtan-shah";
            repo = "nowplaying-cli";
            rev = "v2.1.0";
            hash = "sha256-jPW3WEq1ZhxBojMO+5WF8ohO1rLmlAJKGdh1HfSOR5s=";
        };

        installPhase = ''
            runHook preInstall
            make install PREFIX="$out"
            runHook postInstall
        '';
    });
in

{
    programs.sketchybar = {
        enable = true;

        extraPackages = with pkgs; [
            aerospace
            jq
            nowplaying-cli
            yq
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
