local colors = require("colors")
local layout = require("settings").layout

require("items.apple")
require("items.spaces")
require("items.media")
require("items.weather")
require("items.calendar")

require("items.widgets.battery")
require("items.widgets.volume")
require("items.widgets.wifi")
require("items.widgets.bluetooth")

local function panel(height, color)
	return {
		color = color or colors.panel,
		corner_radius = layout.group_radius,
		height = height or layout.group_height,
		border_width = 0,
	}
end

sbar.add("bracket", "bracket.left", { "apple.logo", "/space\\..*/", "spaces.right_pad" }, {
	background = panel(),
})

sbar.add("bracket", "bracket.media", {
	"/^center\\.media.*/",
	"widgets.weather",
	"widgets.date",
	"widgets.time",
}, {
	background = panel(layout.media_group_height, colors.base),
})

sbar.add("bracket", "bracket.right", {
	"widgets.wifi",
	"widgets.bluetooth",
	"widgets.volume",
	"widgets.battery",
}, {
	background = panel(layout.group_height, colors.base),
})
