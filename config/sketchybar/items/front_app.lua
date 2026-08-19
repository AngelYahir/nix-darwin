local colors = require("colors")
local settings = require("settings")

local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = { drawing = false },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
    color = colors.base,
    padding_left = 8,
    padding_right = 8,
  },
  background = {
    color = colors.rosewater,
    corner_radius = 6,
    height = 20,
    border_width = 1,
    border_color = colors.rosewater,
  },
  padding_left = 8,
  padding_right = 8,
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
