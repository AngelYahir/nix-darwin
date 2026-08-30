local colors = require("colors")
local layout = require("settings").layout

sbar.bar({
  topmost = "window",
  position = "top",
  height = layout.bar_height,
  color = colors.bar.bg,
  border_width = 0,
  padding_left = layout.bar_padding,
  padding_right = layout.bar_padding,
  corner_radius = layout.group_radius,
  blur_radius = 0,
  shadow = true,
  y_offset = layout.bar_offset,
  sticky = true,
})
