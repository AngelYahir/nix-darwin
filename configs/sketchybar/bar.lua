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
  corner_radius = layout.bar_radius,
  margin = layout.bar_margin,
  notch_width = layout.notch_width,
  notch_offset = layout.notch_offset,
  notch_display_height = layout.notch_display_height,
  blur_radius = 0,
  shadow = true,
  y_offset = layout.bar_offset,
  sticky = true,
})
