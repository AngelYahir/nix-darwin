local settings = require("settings")
local colors = require("colors")

local date = sbar.add("item", "widgets.date", {
	position = "center",
	icon = {
		string = os.date("%b %d %a"),
		color = colors.text,
		padding_left = 6,
		padding_right = 2,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 12.0,
		},
	},
	label = { drawing = false },
	update_freq = 3600,
})

local time = sbar.add("item", "widgets.time", {
	position = "center",
	icon = {
		string = os.date("%H:%M"),
		color = colors.accent,
		padding_left = 4,
		padding_right = 6,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
	},
	label = { drawing = false },
	update_freq = 30,
})

date:subscribe({ "forced", "routine", "system_woke" }, function()
	date:set({ icon = { string = os.date("%b %d %a") } })
end)

time:subscribe({ "forced", "routine", "system_woke" }, function()
	time:set({ icon = { string = os.date("%H:%M") } })
end)
