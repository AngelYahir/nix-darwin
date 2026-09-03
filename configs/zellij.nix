{ inputs, pkgs, ... }:

{
    programs.zellij = {
        enable = true;
        package = inputs.nixpkgs-zellij.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zellij;
        enableZshIntegration = true;

        settings = {
            theme = "catppuccin-mocha";
            default_layout = "default";
            pane_frames = false;
            mouse_mode = true;
            copy_on_select = true;
            show_startup_tips = false;
            show_release_notes = false;
            scroll_buffer_size = 10000;
            support_kitty_graphics_protocol = true;
        };

        themes.catppuccin-mocha = ''
            themes {
                catppuccin-mocha {
                    text_unselected {
                        base 205 214 244
                        background 24 24 37
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    text_selected {
                        base 205 214 244
                        background 88 91 112
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    ribbon_selected {
                        base 24 24 37
                        background 203 166 247
                        emphasis_0 243 139 168
                        emphasis_1 250 179 135
                        emphasis_2 245 194 231
                        emphasis_3 137 180 250
                    }
                    ribbon_unselected {
                        base 24 24 37
                        background 205 214 244
                        emphasis_0 243 139 168
                        emphasis_1 205 214 244
                        emphasis_2 137 180 250
                        emphasis_3 245 194 231
                    }
                    table_title {
                        base 203 166 247
                        background 0
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    table_cell_selected {
                        base 205 214 244
                        background 88 91 112
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    table_cell_unselected {
                        base 205 214 244
                        background 24 24 37
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    list_selected {
                        base 205 214 244
                        background 88 91 112
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    list_unselected {
                        base 205 214 244
                        background 24 24 37
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 166 227 161
                        emphasis_3 245 194 231
                    }
                    // Mauve is the configured Catppuccin accent.
                    frame_selected {
                        base 203 166 247
                        background 0
                        emphasis_0 250 179 135
                        emphasis_1 137 220 235
                        emphasis_2 245 194 231
                        emphasis_3 0
                    }
                    frame_highlight {
                        base 203 166 247
                        background 0
                        emphasis_0 180 190 254
                        emphasis_1 245 194 231
                        emphasis_2 203 166 247
                        emphasis_3 203 166 247
                    }
                    exit_code_success {
                        base 166 227 161
                        background 0
                        emphasis_0 137 220 235
                        emphasis_1 24 24 37
                        emphasis_2 245 194 231
                        emphasis_3 137 180 250
                    }
                    exit_code_error {
                        base 243 139 168
                        background 0
                        emphasis_0 249 226 175
                        emphasis_1 0
                        emphasis_2 0
                        emphasis_3 0
                    }
                    multiplayer_user_colors {
                        player_1 245 194 231
                        player_2 137 180 250
                        player_3 203 166 247
                        player_4 249 226 175
                        player_5 137 220 235
                        player_6 166 227 161
                        player_7 243 139 168
                        player_8 180 190 254
                        player_9 250 179 135
                        player_10 148 226 213
                    }
                }
            }
        '';

        layouts.default = ''
            layout {
                default_tab_template {

                // ─────────────────────────────────────────────
                // TOP BAR
                // ─────────────────────────────────────────────

                    pane size=1 borderless=true {
                        plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                            format_left "#[fg=#89b4fa]#[bg=#89b4fa,fg=#11111b,bold] {session} #[fg=#89b4fa]"
                            format_center "{tabs}"
                            format_right "{command_git_branch}{datetime}"
                            format_space  ""

                            border_enabled "false"

                            // Session
                            tab_normal "#[fg=#b4befe]#[bg=#b4befe,fg=#11111b] {index} {name}{sync_indicator}{fullscreen_indicator}{floating_indicator} #[bg=#1e1e2e,fg=#b4befe]"
                            tab_active "#[fg=#cba6f7]#[bg=#cba6f7,fg=#11111b,bold] {index} {name}{sync_indicator}{fullscreen_indicator}{floating_indicator} #[bg=#1e1e2e,fg=#cba6f7]"

                            tab_normal_fullscreen "#[fg=#b4befe]#[bg=#b4befe,fg=#11111b] {index} {name} 󰊓 #[bg=#1e1e2e,fg=#b4befe]"
                            tab_active_fullscreen "#[fg=#cba6f7]#[bg=#cba6f7,fg=#11111b,bold] {index} {name} 󰊓 #[bg=#1e1e2e,fg=#cba6f7]"

                            tab_normal_sync "#[fg=#b4befe]#[bg=#b4befe,fg=#11111b] {index} {name}  #[bg=#1e1e2e,fg=#b4befe]"
                            tab_active_sync "#[fg=#cba6f7]#[bg=#cba6f7,fg=#11111b,bold] {index} {name}  #[bg=#1e1e2e,fg=#cba6f7]"

                            tab_separator " "
                            tab_sync_indicator " "
                            tab_fullscreen_indicator " 󰊓"
                            tab_floating_indicator " 󰹙"

                            command_git_branch_command "git rev-parse --abbrev-ref HEAD"
                            command_git_branch_format "#[fg=#94e2d5]#[bg=#94e2d5,fg=#11111b,bold]  {stdout} #[bg=#1e1e2e,fg=#94e2d5]"
                            command_git_branch_interval "10"
                            command_git_branch_rendermode "static"
                            command_git_branch_cwd "{focused_pane_cwd}"

                            datetime "#[fg=#cba6f7]#[bg=#cba6f7,fg=#11111b,bold]  {format} #[bg=#1e1e2e,fg=#cba6f7]"
                            datetime_format "%H:%M"
                            datetime_timezone "America/Monterrey"
                        }
                    }

                    // ─────────────────────────────────────────────
                    // TERMINAL
                    // ─────────────────────────────────────────────

                    children

                    // ─────────────────────────────────────────────
                    // BOTTOM BAR
                    // ─────────────────────────────────────────────

                    pane size=1 borderless=true {
                        plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
                            format_left   "{mode}"
                            format_center ""
                            format_right  "{datetime}"
                            format_space  ""

                            border_enabled "false"

                            mode_normal "#[fg=#a6e3a1]#[bg=#a6e3a1,fg=#11111b,bold] 󰘧 {name} #[bg=#1e1e2e,fg=#a6e3a1]"
                            mode_locked "#[fg=#f38ba8]#[bg=#f38ba8,fg=#11111b,bold]  {name} #[bg=#1e1e2e,fg=#f38ba8]"
                            mode_resize "#[fg=#fab387]#[bg=#fab387,fg=#11111b,bold] 󰩨 {name} #[bg=#1e1e2e,fg=#fab387]"
                            mode_pane "#[fg=#89b4fa]#[bg=#89b4fa,fg=#11111b,bold]  {name} #[bg=#1e1e2e,fg=#89b4fa]"
                            mode_tab "#[fg=#f9e2af]#[bg=#f9e2af,fg=#11111b,bold] 󰓩 {name} #[bg=#1e1e2e,fg=#f9e2af]"
                            mode_scroll "#[fg=#f5c2e7]#[bg=#f5c2e7,fg=#11111b,bold] 󰘍 {name} #[bg=#1e1e2e,fg=#f5c2e7]"
                            mode_search "#[fg=#94e2d5]#[bg=#94e2d5,fg=#11111b,bold]  {name} #[bg=#1e1e2e,fg=#94e2d5]"
                            mode_enter_search "#[fg=#94e2d5]#[bg=#94e2d5,fg=#11111b,bold]  {name} #[bg=#1e1e2e,fg=#94e2d5]"
                            mode_session "#[fg=#cba6f7]#[bg=#cba6f7,fg=#11111b,bold] 󰍹 {name} #[bg=#1e1e2e,fg=#cba6f7]"
                            mode_move "#[fg=#89dceb]#[bg=#89dceb,fg=#11111b,bold] 󰆾 {name} #[bg=#1e1e2e,fg=#89dceb]"
                            mode_tmux "#[fg=#b4befe]#[bg=#b4befe,fg=#11111b,bold] {name} #[bg=#1e1e2e,fg=#b4befe]"

                            mode_default_to_mode "normal"

                            datetime "#[fg=#cba6f7]#[bg=#cba6f7,fg=#11111b,bold]  {format} #[bg=#1e1e2e,fg=#cba6f7]"
                            datetime_format "%H:%M"
                            datetime_timezone "America/Monterrey"
                        }
                    }
                }
            }
        '';
    };
}
