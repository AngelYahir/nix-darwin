local settings = require("settings")
local colors = require("colors")

local WTTR_URL = "https://wttr.in/?format=%t&m"

local weather = sbar.add("item", "widgets.weather", {
	position = "center",
	icon = {
		string = "􀆭",
		color = colors.accent,
		padding_left = 5,
		padding_right = 2,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 13.0,
		},
	},
	label = {
		string = "--°",
		color = colors.text,
		padding_left = 2,
		padding_right = 6,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
	},
	update_freq = 1800,
})

local STALE_AFTER_S = 2 * 60 * 60
local STALE_ALPHA = 0.35
local last_ok = nil
local showing_stale = nil

local function set_stale(stale)
	if stale == showing_stale then
		return
	end
	showing_stale = stale
	weather:set({
		icon = { color = stale and colors.with_alpha(colors.accent, STALE_ALPHA) or colors.accent },
		label = { color = stale and colors.with_alpha(colors.text, STALE_ALPHA) or colors.text },
	})
end

local function update()
	sbar.exec("curl -s --max-time 5 '" .. WTTR_URL .. "'", function(out)
		local temp = out and out:gsub("^%s*(.-)%s*$", "%1") or ""
		if temp ~= "" and not temp:lower():find("unknown") then
			last_ok = os.time()
			weather:set({ label = { string = temp } })
			set_stale(false)
		else
			set_stale(last_ok == nil or (os.time() - last_ok) > STALE_AFTER_S)
		end
	end)
end

weather:subscribe({ "routine", "system_woke", "forced" }, update)

update()
