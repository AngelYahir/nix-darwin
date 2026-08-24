{ ... }:
{
    programs.ghostty = {
        enable = true;
        package = null;

        enableZshIntegration = true;

        settings = {
            font-family = "JetBrains Nerd Font Mono";
            font-size = 14;

            macos-titlebar-style = "hidden";
            window-padding-x = 10;
            window-padding-y = 8;
            window-padding-balance = true;

            shell-integration = "zsh";

            cursor-style = "block";
            cursor-style-blink = true;

            window-save-state = "never";

            window-theme = "ghostty";

        };

    };
}