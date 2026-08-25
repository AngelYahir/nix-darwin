{ pkgs, ... }:

{
    programs.zellij = {
        enable = true;
        enableZshIntegration = true;

        settings = {
            theme = "catppuccin-mocha";
            default_layout = "default";
            pane_frames = false;
            mouse_mode = true;
            copy_on_select = false;
            show_startup_tips = false;
            show_release_notes = false;
            scroll_buffer_size = 10000;
        };

        themes.catppuccin-mocha = ''
            themes {
                catppuccin-mocha {
                    background "#585b70"
                    foreground "#cdd6f4"
                    black "#181825"
                    red "#f38ba8"
                    green "#a6e3a1"
                    yellow "#f9e2af"
                    blue "#89b4fa"
                    magenta "#f5c2e7"
                    cyan "#89dceb"
                    white "#cdd6f4"
                    orange "#fab387"
                    bright_black "#585b70"
                    bright_red "#f38ba8"
                    bright_green "#a6e3a1"
                    bright_yellow "#f9e2af"
                    bright_blue "#89b4fa"
                    bright_magenta "#f5c2e7"
                    bright_cyan "#94e2d5"
                    bright_white "#cdd6f4"
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
