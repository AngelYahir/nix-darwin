local colors = require("colors")

sbar.bar({
  topmost = "window",
  position = "top",
  height = 32,
  color = true and colors.bar.bg or colors.transparent,
  border_width = 0,
  border_color = colors.bar.border,
  padding_left = 8,
  padding_right = 8,

  margin = 6,

  corner_radius = 8,

  blur_radius = true and (colors.bar.blur or 0) or 0,
  shadow = true,
  y_offset = true and 8 or 6,
  margin = 128,
  sticky = true,
})