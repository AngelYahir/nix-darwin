local colors = require("colors")
local settings = require("settings")

local GRAPH_WIDTH = 35
local CLICK_SCRIPT = "open -a 'Activity Monitor'"

local cpu_caption = sbar.add("item", "widgets.cpu.caption", {
	position = "right",
	width = 0,
	click_script = CLICK_SCRIPT,
	icon = { drawing = false },
	label = {
		string = "CPU",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 8.0,
		},
		color = colors.with_alpha(colors.text, 0.6),
		y_offset = 6,
	},
})

local cpu_percent = sbar.add("item", "widgets.cpu.percent", {
	position = "right",
	click_script = CLICK_SCRIPT,
	icon = { drawing = false },
	label = {
		string = "0%",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		color = colors.text,
		y_offset = -4,
	},
})

local cpu = sbar.add("graph", "widgets.cpu", GRAPH_WIDTH, {
	position = "right",
	click_script = CLICK_SCRIPT,
	graph = {
		color = colors.blue,
		fill_color = colors.with_alpha(colors.blue, 0.30),
		line_width = 1.5,
	},
	background = { height = 24, drawing = true, color = colors.transparent },
	icon = { drawing = false },
	label = { drawing = false },
	update_freq = 2,
})

cpu:subscribe({ "routine", "system_woke", "forced" }, function()
	sbar.exec([[top -l 2 -n 0 | grep -E "^CPU usage" | tail -1]], function(out)
		local user = tonumber(out:match("([%d%.]+)%% user")) or 0
		local sys = tonumber(out:match("([%d%.]+)%% sys")) or 0
		local used = user + sys
		local pct = math.floor(used + 0.5)

		local color
		if used >= 80 then
			color = colors.red
		elseif used >= 50 then
			color = colors.peach
		elseif used >= 25 then
			color = colors.yellow
		else
			color = colors.blue
		end

		cpu:set({
			graph = { color = color, fill_color = colors.with_alpha(color, 0.30) },
		})
		cpu_percent:set({ label = { string = pct .. "%", color = color } })
		cpu:push({ used / 100.0 })
	end)
end)
