local wezterm = require ('wezterm');
local act = wezterm.action;

local mod = {};

mod.SUPER = "CTRL"
mod.SUPER_REV = "CTRL|SHIFT"

local keys = {
  -- misc
  { key = "Enter", 	mods = mod.SUPER_REV, 	action = act.ToggleFullScreen },
  { key = "f", 		mods = mod.SUPER_REV, 	action = act.Search({ CaseInSensitiveString = "" }) },

  -- Copy/paste
  { key = "c", 		mods = mod.SUPER_REV,	action = act.CopyTo("Clipboard") },
  { key = "v", 		mods = mod.SUPER_REV, 	action = act.PasteFrom("Clipboard") },

  -- Tabs
  { key = "w", 		mods = mod.SUPER_REV, 	action = act.CloseCurrentTab({ confirm = false }) },
  { key = "t", 		mods = mod.SUPER_REV, 	action = act.SpawnTab("DefaultDomain") },

  -- Tab Nav
  { key = "[", 		mods = mod.SUPER, 	action = act.ActivateTabRelative(-1) },
  { key = "]", 		mods = mod.SUPER, 	action = act.ActivateTabRelative(1) },

  -- Window
  { key = "n", 		mods = mod.SUPER, 	action = act.SpawnWindow },

  -- Split
  { key = [[|]], 	mods = mod.SUPER_REV, 	action = act.SplitHorizontal },
  { key = [[?]], 	mods = mod.SUPER_REV, 	action = act.SplitVertical },
  { key = [[-]], 	mods = mod.SUPER_REV, 	action = act.CloseCurrentPane({ confirm = true }) },

  -- Pane zoom
  { key = "=", 		mods = mod.SUPER, 	action = act.TogglePaneZoomState },
  
  -- Pane Nav
  { key = "h", 		mods = "CTRL|CMD", 	action = act.ActivatePaneDirection("Left") },
  { key = "j", 		mods = "CTRL|CMD", 	action = act.ActivatePaneDirection("Down") },
  { key = "k", 		mods = "CTRL|CMD", 	action = act.ActivatePaneDirection("Up") },
  { key = "l", 		mods = "CTRL|CMD", 	action = act.ActivatePaneDirection("Right") },

  -- Pane Resize
  { key = "H", 		mods = mod.SUPER_REV, 	action = act.AdjustPaneSize({ "Left", 1 }) },
  { key = "J", 		mods = mod.SUPER_REV, 	action = act.AdjustPaneSize({ "Down", 1 }) },
  { key = "K", 		mods = mod.SUPER_REV, 	action = act.AdjustPaneSize({ "Up", 1 }) },
  { key = "L", 		mods = mod.SUPER_REV, 	action = act.AdjustPaneSize({ "Right", 1 }) },

  -- Font Size
  { key = "UpArrow", 		mods = mod.SUPER_REV, 	action = act.IncreaseFontSize },
  { key = "DownArrow", 		mods = mod.SUPER_REV, 	action = act.DecreaseFontSize },
  { key = "RightArrow", 		mods = mod.SUPER_REV, 	action = act.ResetFontSize },

  {
    key = "f",
    mods = "LEADER",
    action = act.ActivateKeyTable({
      name = "resize_font",
      one_shot = false,
    }),
  },
  -- resize panes
  {
    key = "p",
    mods = "LEADER",
    action = act.ActivateKeyTable({
      name = "resize_pane",
      one_shot = false,
    }),
  },
  -- rename tab bar
  {
    key = "R",
    mods = "CTRL|SHIFT",
    action = act.PromptInputLine({
      description = "Enter new name for tab",
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
}

local key_tables = {
  resize_font = {
    { key = "k", action = act.IncreaseFontSize },
    { key = "j", action = act.DecreaseFontSize },
    { key = "r", action = act.ResetFontSize },
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
  },
  resize_pane = {
    { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
    { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "q", action = "PopKeyTable" },
  },
}

local mouse_bindings = {
  -- Ctrl-click will open the link under the mouse cursor
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
  -- Move mouse will only select text and not copy text to clipboard
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("Cell"),
  },
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.ExtendSelectionToMouseCursor("Cell"),
  },
  {
    event = { Drag = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.ExtendSelectionToMouseCursor("Cell"),
  },
  -- Triple Left click will select a line
  {
    event = { Down = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("Line"),
  },
  {
    event = { Up = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("Line"),
  },
  -- Double Left click will select a word
  {
    event = { Down = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("Word"),
  },
  {
    event = { Up = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor("Word"),
  },
  -- Turn on the mouse wheel to scroll the screen
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "NONE",
    action = act.ScrollByCurrentEventWheelDelta,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "NONE",
    action = act.ScrollByCurrentEventWheelDelta,
  },
}

return {
  disable_default_key_bindings = true,
  disable_default_mouse_bindings = true,
  leader = { key = "Space", mods = "CTRL|SHIFT" },
  keys = keys,
  key_tables = key_tables,
  mouse_bindings = mouse_bindings,
}
