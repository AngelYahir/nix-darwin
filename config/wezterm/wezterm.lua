local wezterm = require "wezterm"

local keybindings = require("bindings")

require("events.title").setup()
require("events.status").setup()	
require("events.tab").setup()

function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Latte"
  end
end

return {
    -- General settings
    --default_prog = { 'pwsh.exe', '-NoLogo' }, -- Change this to your shell of choice
    window_close_confirmation = "NeverPrompt",
    -- Tab bar settings
    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = false,
    use_fancy_tab_bar = true,
    tab_max_width = 25,
    tab_bar_at_bottom = false,
    show_tab_index_in_tab_bar = true,
    switch_to_last_active_tab_when_closing_tab = true,
    -- Font settings
    font = wezterm.font("Hack Nerd Font", {weight="Regular"}),
    font_size = 12,
    -- Appearence settings
    term = "xterm-256color",
    front_end = "WebGpu",
    webgpu_power_preference = "HighPerformance",
    window_decorations = "RESIZE",
    default_cursor_style = "BlinkingBar",
    --win32_system_backdrop = "Acrylic",
    window_background_opacity = 0.85,
    window_padding = {
      left = 1,
      right = 1,
      top = 0,
      bottom = 0,
    },
    window_frame = {
      active_titlebar_bg = "#1e1e2e",
      inactive_titlebar_bg = "#1e1e2e",
    },
    initial_cols = 100,
    initial_rows = 30,
    inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 },
    color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),

    -- Keybindings
    keys = keybindings.keys,
    mouse_bindings = keybindings.mouse_bindings,
    key_tables = keybindings.key_tables,
}
