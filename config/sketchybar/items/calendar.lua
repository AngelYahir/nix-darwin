local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = sbar.add("item", {
  icon = {
    color = colors.mauve,
    padding_left = 10,
    padding_right = 6,
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.base,
    padding_right = 10,
    padding_left = 10,
    width = 52,
    align = "center",
    font = { 
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    background = {
      color = colors.rosewater,
      border_color = colors.rosewater,
      border_width = 1,
      corner_radius = 8,
      height = 24,
    }
  },
  position = "right",
  update_freq = 30,
  padding_left = 3,
  padding_right = 3,
  background = {
    color = colors.base,
    border_color = colors.lavender,
    border_width = 1,
    corner_radius = 8,
  },
  click_script = "open -a 'Calendar'"
})

-- Double border for calendar using a single item bracket
sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 32,
    border_color = colors.lavender,
    border_width = 2,
    corner_radius = 10,
  }
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
  cal:set({ icon = os.date("%a. %d %b."), label = os.date("%H:%M") })
end)
