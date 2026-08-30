local settings = require("settings")
local colors = require("colors")
local layout = settings.layout

sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 14.0,
    },
    color = colors.text,
    padding_left = settings.padding,
    padding_right = settings.padding,
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Semibold"],
      size = 13.0,
    },
    color = colors.text,
    padding_left = settings.padding,
    padding_right = settings.padding,
  },
  background = {
    height = layout.item_height,
    corner_radius = layout.item_radius,
    border_width = 0,
    color = colors.transparent,
  },
  popup = {
    background = {
      border_width = 1,
      corner_radius = 10,
      border_color = colors.popup.border,
      color = colors.popup.bg,
      shadow = { drawing = true },
    },
    blur_radius = 30,
  },
  padding_left = 3,
  padding_right = 3,
  scroll_texts = true,
})
