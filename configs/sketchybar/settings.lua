local notch = true -- Change only this boolean to switch notch mode.
local mode = notch
		and {
			bar_height = 38,
			bar_offset = 0,
			bar_radius = 0,
			bar_margin = 0,
			notch_width = 200,
			notch_offset = 0,
			notch_display_height = 38,
			position = { media = "q", info = "e" },
		}
	or {
		bar_height = 32,
		bar_offset = 4,
		bar_radius = 9,
		position = { media = "center", info = "center" },
	}

return {
	notch = notch,
	position = mode.position,
	padding = 4,

	icons = "sf-symbols",
	font = {
		text = "SF Pro",
		numbers = "SF Mono",
		icons = "JetBrainsMono Nerd Font",

		style_map = {
			["Regular"] = "Regular",
			["Medium"] = "Medium",
			["Semibold"] = "Semibold",
			["Bold"] = "Bold",
			["Heavy"] = "Heavy",
			["Black"] = "Black",
		},
	},

	layout = {
		bar_height = mode.bar_height,
		bar_offset = mode.bar_offset,
		bar_radius = mode.bar_radius,
		bar_margin = mode.bar_margin,
		notch_width = mode.notch_width,
		notch_offset = mode.notch_offset,
		notch_display_height = mode.notch_display_height,
		bar_padding = 10,
		group_height = 26,
		group_radius = 9,
		item_height = 22,
		item_radius = 7,
		media_group_height = 28,
		media_artwork_size = 24,
		media_width = 172,
		media_max_chars = 20,
		media_spectrum_width = 42,
	},
}
