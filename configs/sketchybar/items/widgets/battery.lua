local utils = require("utils")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	icon = { drawing = false },
	label = {
		drawing = false,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		color = colors.text,
		padding_left = 8,
		padding_right = 10,
	},
	update_freq = 30,
})

local remaining_time = sbar.add("item", {
	position = "popup." .. battery.name,
	icon = {
		string = "Time remaining:",
		width = 110,
		align = "left",
		padding_left = 15,
	},
	label = {
		string = "No estimate",
		width = 110,
		align = "right",
		padding_right = 15,
	},
})

battery:subscribe({ "routine", "power_source_change", "system_woke", "forced" }, function()
	sbar.exec("pmset -g batt", function(batt_info)
		local found, _, charge = batt_info:find("(%d+)%%")
		if not found then
			battery:set({ label = { drawing = false } })
			return
		end
		charge = tonumber(charge)

		local charging = batt_info:find("AC Power")

		local color
		if charging then
			color = colors.blue
		elseif charge > 60 then
			color = colors.green
		elseif charge > 40 then
			color = colors.yellow
		elseif charge > 20 then
			color = colors.peach
		elseif charge > 10 then
			color = colors.peach
		else
			color = colors.red
		end

		local lead = charge < 10 and "0" or ""

		battery:set({
			label = { drawing = true, string = lead .. charge .. "%", color = color },
		})
	end)
end)

battery:subscribe("mouse.clicked", function(env)
	local drawing = battery:query().popup.drawing
	battery:set({ popup = { drawing = "toggle" } })

	if drawing == "off" then
		sbar.exec("pmset -g batt", function(batt_info)
			local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
			local label = found and remaining .. "h" or "No estimate"
			remaining_time:set({ label = label })
		end)
	end
end)

utils.hover_lift(battery)
