local colors = require("colors")

return {
  padding = 3,
  group_padding = 3,

  icons = "sf-symbols",
  font = {
    text = "SF Pro",
    numbers = "SF Mono",

    style_map = {
      ["Regular"] = "Regular",
      ["Medium"] = "Medium",
      ["Semibold"] = "Semibold",
      ["Bold"] = "Bold",
      ["Heavy"] = "Heavy",
      ["Black"] = "Black",
    }
  },

  widget_bracket_bg = {
    color = colors.transparent,
    border_width = 0,
    corner_radius = 32,
    height = 32,
  }
}