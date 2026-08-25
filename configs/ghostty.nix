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
            window-padding-x = 4;
            window-padding-y = 8;
            window-padding-balance = true;
            confirm-close-surface = false;

            shell-integration = "zsh";

            background-blur = "macos-glass-regular";
            background-opacity = 0.82;
            background-opacity-cells = false;

            background = "#1e1e2e";
            foreground = "#cdd6f4";

            cursor-color = "#f5e0dc";
            cursor-text = "#11111b";

            selection-background = "#353749";
            selection-foreground = "#cdd6f4";

            split-divider-color = "#313244";

            palette = [
                "0=#45475a"
                "1=#f38ba8"
                "2=#a6e3a1"
                "3=#f9e2af"
                "4=#89b4fa"
                "5=#f5c2e7"
                "6=#94e2d5"
                "7=#a6adc8"
                "8=#585b70"
                "9=#f38ba8"
                "10=#a6e3a1"
                "11=#f9e2af"
                "12=#89b4fa"
                "13=#f5c2e7"
                "14=#94e2d5"
                "15=#bac2de"
            ];

            cursor-style = "block";
            cursor-style-blink = true;

            window-save-state = "never";
        };

    };
}