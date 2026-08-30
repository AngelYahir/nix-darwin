local colors = require("colors")
local settings = require("settings")

local bluetooth = sbar.add("item", "widgets.bluetooth", {
	position = "right",
	icon = {
		string = "󰂯",
		font = {
			family = settings.font.icons,
			style = "Regular",
			size = 14.0,
		},
		color = colors.overlay0,
		padding_left = 8,
		padding_right = 4,
	},
	label = { drawing = false },
	update_freq = 60,
	updates = true,
})

local function update()
	sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(out)
		local state = out:match("State:%s*(%w+)")
		local on = state == "On"

		local has_connected = false
		if on then
			local connected_block = out:match("Connected:(.-)Not Connected:") or out:match("Connected:(.-)$")
			if connected_block and connected_block:match("%S") then
				has_connected = connected_block:match("Address:") ~= nil
			end
		end

		local color
		if not on then
			color = colors.overlay0
		elseif has_connected then
			color = colors.yellow
		else
			color = colors.text
		end

		bluetooth:set({ icon = { color = color } })
	end)
end

bluetooth:subscribe({ "routine", "system_woke", "forced", "volume_change" }, update)
bluetooth:subscribe("mouse.clicked", update)
update()
