{ pkgs, ... }:

{
    services.aerospace = {
        enable = true;

        settings = {
            default-root-container-layout = "tiles";
            default-root-container-orientation = "auto";

            gaps = {
                inner.horizontal = 6;
                inner.vertical = 6;

                outer = {
                    top = 36;

                    right = 8;
                    bottom = 8;
                    left = 8;
                };
            };

            mode.main.binding = {
                alt-h = "focus left";
                alt-j = "focus down";
                alt-k = "focus up";
                alt-l = "focus right";

                alt-Shift-h = "move left";
                alt-Shift-j = "move down";
                alt-Shift-k = "move up";
                alt-Shift-l = "move right";


                # Cambiar monitor
                alt-left = "focus-monitor left";
                alt-right = "focus-monitor right";

                # Mandar ventana entre monitores
                alt-shift-left = "move-node-to-monitor left --focus-follows-window";
                alt-shift-right = "move-node-to-monitor right --focus-follows-window";

                # Workspaces
                alt-1 = "workspace 1";
                alt-2 = "workspace 2";
                alt-3 = "workspace 3";
                alt-4 = "workspace 4";
                alt-5 = "workspace 5";
                alt-8 = "workspace 8";
                alt-9 = "workspace 9";

                alt-shift-1 = "move-node-to-workspace 1 --focus-follows-window";
                alt-shift-2 = "move-node-to-workspace 2 --focus-follows-window";
                alt-shift-3 = "move-node-to-workspace 3 --focus-follows-window";
                alt-shift-4 = "move-node-to-workspace 4 --focus-follows-window";
                alt-shift-5 = "move-node-to-workspace 5 --focus-follows-window";
                alt-shift-8 = "move-node-to-workspace 8 --focus-follows-window";
                alt-shift-9 = "move-node-to-workspace 9 --focus-follows-window";

                alt-enter = ''
                    exec-and-forget osascript -e '
                        tell application "Ghostty"
                            new window
                        end tell
                    '
                '';

                alt-f = "layout floating tiling";
                alt-r = "mode resize";

            };

            workspace-to-monitor-force-assignment = {
                "1" = "main";
                "2" = "main";
                "3" = "main";
                "4" = "main";
                "5" = "main";
                "8" = "secondary";
                "9" = "secondary";
            };

            resize.binding = {
                h = "resize width -50";
                l = "resize width +50";

                j = "resize height +50";
                k = "resize height -50";

                shift-h = "resize width -10";
                shift-l = "resize width +10";

                shift-j = "resize height +10";
                shift-k = "resize height -10";

                enter = "mode main";
                esc = "mode main";
            };

            # Sketchy bar
            exec-on-workspace-change = [
                "/bin/bash"
                "-c"
                "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
            ];
        };
    };
}