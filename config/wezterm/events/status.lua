local wezterm = require("wezterm")
local M = {}

M.separator_char = " |  "

M.colors = {
  stat_fg = "#1e1e2e", 
  stat_bg = "#ea999c",
  cmd_fg = "#1e1e2e",
  cmd_bg = "#eebebe",
  date_fg = "#1e1e2e",  
  date_bg = "#cba6f7"
}

M.cells = {}

---@param text string
---@param icon string
---@param fg string
---@param bg string
M.push = function(text, icon, fg, bg, pbg )
  table.insert(M.cells, { Foreground = { Color =  bg } })
  table.insert(M.cells, { Background = { Color =  pbg } })
  table.insert(M.cells, { Text = " " })

  table.insert(M.cells, { Foreground = { Color = fg } })
  table.insert(M.cells, { Background = { Color = bg } })
  table.insert(M.cells, { Attribute = { Intensity = "Bold" } })
  table.insert(M.cells, { Text =  icon .. " " .. text .. "  " })


  table.insert(M.cells, "ResetAttributes")
end

M.set_status = function(window)
  local stat = window:active_workspace()
  if window:active_key_table() then stat = window:active_key_table() end
  if window:leader_is_active() then stat = "LDR" end
  M.push(stat, "  ", M.colors.stat_fg, M.colors.stat_bg, M.colors.stat_fg)
end

M.set_cmd = function(pane)
  local basename = function(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end
  local cmd = basename(pane:get_foreground_process_name())
  M.push(cmd, "  ", M.colors.cmd_fg, M.colors.cmd_bg, M.colors.stat_bg)
end

M.set_date = function()
  local date = wezterm.strftime("%a %H:%M")
  M.push(date, "  ", M.colors.date_fg, M.colors.date_bg, M.colors.cmd_bg)
end

M.setup = function()
  wezterm.on("update-right-status", function(window, pane)
    M.cells = {}

    M.set_status(window)
    M.set_cmd(pane)
    M.set_date()
    M.push(" ", " 󰄛", M.colors.date_fg, "#babbf1", M.colors.date_bg)

    window:set_right_status(wezterm.format(M.cells))
  end)
end

return M
