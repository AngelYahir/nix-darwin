local utils = require("utils")
local colors = require("colors")

local apple = sbar.add("item", "apple.logo", {
	position = "left",
	width = 24,
	background = {
		image = {
			string = os.getenv("HOME") .. "/.config/sketchybar/assets/sakura.png",
			scale = 0.04,
		},
		color = colors.transparent,
		height = 20,
	},
	icon = { drawing = false },
	label = { drawing = false },
	padding_left = 7,
	padding_right = 5,
	click_script = "open -a 'System Settings'",
})

utils.hover_lift(apple)
