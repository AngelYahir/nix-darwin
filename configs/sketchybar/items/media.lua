local utils = require("utils")
local colors = require("colors")
local settings = require("settings")
local icons = require("icons")
local layout = settings.layout

local CIDER_URL = "http://127.0.0.1:10767/api/v1/playback"
local CIDER_AUTH = [[
cider_token=$(yq -r '.connectivity.apiTokens[]? | select(.name == "SketchyBar") | .token' "$HOME/Library/Application Support/sh.cider.genten/spa-config.yml")
[ -n "$cider_token" ] || exit 1
]]
local CIDER_STATUS = CIDER_AUTH
	.. string.format(
		[[
now_playing=$(curl -fsS --max-time 2 -H "apptoken: $cider_token" %q) || exit 1
play_state=$(curl -fsS --max-time 2 -H "apptoken: $cider_token" %q) || exit 1
playing=$(printf '%%s' "$play_state" | jq -r '.is_playing // false')
printf '%%s' "$now_playing" | jq -r --arg playing "$playing" '.info | [.name // "", .artistName // "", $playing, .artwork.url // ""] | .[]'
]],
		CIDER_URL .. "/now-playing",
		CIDER_URL .. "/is-playing"
	)

local playpause = sbar.add("item", "center.media.playpause", {
	position = "center",
	width = 24,
	icon = {
		string = icons.media.play,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.with_alpha(colors.accent, 0.45),
		padding_left = 6,
		padding_right = 6,
	},
	label = { drawing = false },
})

local artwork = sbar.add("item", "center.media.artwork", {
	position = "center",
	width = layout.media_artwork_size,
	background = {
		image = { string = "", scale = 0.25, corner_radius = 5 },
		color = colors.transparent,
		height = layout.media_artwork_size,
		corner_radius = 5,
	},
	icon = { drawing = false },
	label = { drawing = false },
	drawing = false,
	padding_left = 3,
	padding_right = 3,
})

local media = sbar.add("item", "center.media", {
	position = "center",
	icon = { drawing = false },
	scroll_texts = false,
	label = {
		string = "No media playing",
		width = layout.media_width,
		align = "left",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 13,
		},
		color = colors.rosewater,
		padding_left = 9,
		padding_right = 10,
	},
	popup = {
		align = "center",
		horizontal = true,
		background = {
			color = colors.popup.bg,
			corner_radius = 9,
			border_width = 1,
			border_color = colors.popup.border,
			height = 56,
		},
	},
	-- media_change is unreliable on recent macOS versions; polling is the fallback.
	update_freq = 2,
	updates = true,
})

local popup_artwork = sbar.add("item", "popup.center.media.art", {
	position = "popup.center.media",
	width = 48,
	background = {
		image = { string = "", scale = 0.5, corner_radius = 6 },
		color = colors.transparent,
		height = 48,
		corner_radius = 6,
	},
	icon = { drawing = false },
	label = { drawing = false },
	drawing = false,
	padding_left = 10,
	padding_right = 6,
})

local popup_title = sbar.add("item", "popup.center.media.title", {
	position = "popup.center.media",
	icon = { drawing = false },
	label = {
		string = "",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 13,
		},
		color = colors.rosewater,
		padding_left = 4,
		padding_right = 4,
	},
})

local popup_artist = sbar.add("item", "popup.center.media.artist", {
	position = "popup.center.media",
	icon = { drawing = false },
	label = {
		string = "",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 12,
		},
		color = colors.with_alpha(colors.text, 0.55),
		padding_left = 2,
		padding_right = 10,
	},
})

local popup_prev = sbar.add("item", "popup.center.media.prev", {
	position = "popup.center.media",
	icon = {
		string = icons.media.back,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.with_alpha(colors.accent, 0.85),
		padding_left = 12,
		padding_right = 8,
	},
	label = { drawing = false },
})

local popup_playpause = sbar.add("item", "popup.center.media.playpause", {
	position = "popup.center.media",
	icon = {
		string = icons.media.play,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.accent,
		padding_left = 8,
		padding_right = 8,
	},
	label = { drawing = false },
})

local popup_next = sbar.add("item", "popup.center.media.next", {
	position = "popup.center.media",
	icon = {
		string = icons.media.forward,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.with_alpha(colors.accent, 0.85),
		padding_left = 8,
		padding_right = 12,
	},
	label = { drawing = false },
})

local current_track_key = nil
local last_label_state = nil
local last_play_state = nil
local active_source = nil
local poll_in_flight = false
local art_slot = 0

local MAX_LABEL_CHARS = layout.media_max_chars
local ART_PATHS = {
	"/tmp/sketchybar-media-art-a.png",
	"/tmp/sketchybar-media-art-b.png",
}

local function char_width(cp)
	if
		(cp >= 0x1100 and cp <= 0x115F) -- Hangul Jamo
		or (cp >= 0x2E80 and cp <= 0x303E) -- CJK radicals, Kangxi, punctuation
		or (cp >= 0x3041 and cp <= 0x33FF) -- Hiragana, Katakana, CJK symbols
		or (cp >= 0x3400 and cp <= 0x4DBF) -- CJK Ext A
		or (cp >= 0x4E00 and cp <= 0x9FFF) -- CJK Unified
		or (cp >= 0xA000 and cp <= 0xA4CF) -- Yi
		or (cp >= 0xAC00 and cp <= 0xD7A3) -- Hangul syllables
		or (cp >= 0xF900 and cp <= 0xFAFF) -- CJK compatibility
		or (cp >= 0xFE30 and cp <= 0xFE4F) -- CJK compatibility forms
		or (cp >= 0xFF00 and cp <= 0xFF60) -- Fullwidth forms
		or (cp >= 0xFFE0 and cp <= 0xFFE6) -- Fullwidth signs
		or (cp >= 0x20000 and cp <= 0x3FFFD) -- CJK Ext B+
	then
		return 2
	end
	return 1
end

local function display_width(s)
	local w = 0
	for _, cp in utf8.codes(s) do
		w = w + char_width(cp)
	end
	return w
end

local function truncate(s, n)
	if display_width(s) <= n then
		return s
	end
	local budget = n - 1
	local w = 0
	local out = {}
	for _, cp in utf8.codes(s) do
		local cw = char_width(cp)
		if w + cw > budget then
			break
		end
		w = w + cw
		out[#out + 1] = utf8.char(cp)
	end
	return table.concat(out) .. "…"
end

local function update_track_info(title, artist, source, artwork_url)
	local key = source .. "|" .. (title or "") .. "|" .. (artist or "") .. "|" .. (artwork_url or "")
	if key == current_track_key then
		return
	end
	current_track_key = key

	popup_title:set({ label = { string = title or "" } })
	popup_artist:set({ label = { string = artist or "" } })

	if source == "cider" and (not artwork_url or artwork_url == "") then
		artwork:set({ drawing = false })
		popup_artwork:set({ drawing = false })
		return
	end

	art_slot = art_slot % #ART_PATHS + 1
	local path = ART_PATHS[art_slot]
	local download = path .. ".download"
	local ready = path .. ".ready.png"
	local acquire
	if source == "cider" then
		acquire = string.format("curl -fsSL --max-time 5 %q -o %q", artwork_url, download)
	else
		acquire = string.format("nowplaying-cli get artworkData 2>/dev/null | base64 -D > %q", download)
	end

	local command = acquire
		.. string.format(
			" && sips -s format png -Z 96 %q --out %q >/dev/null 2>&1"
				.. " && mv -f %q %q && rm -f %q && echo ok",
			download,
			ready,
			ready,
			path,
			download
		)

	sbar.exec(command, function(out)
		if current_track_key ~= key then
			return
		end
		if out and out:match("ok") then
			local image = { drawing = true, string = path }
			artwork:set({ drawing = true, background = { image = image } })
			popup_artwork:set({ drawing = true, background = { image = image } })
		else
			artwork:set({ drawing = false })
			popup_artwork:set({ drawing = false })
		end
	end)
end

local function clear_track_info()
	current_track_key = nil
	artwork:set({ drawing = false })
	popup_artwork:set({ drawing = false })
	popup_title:set({ label = { string = "" } })
	popup_artist:set({ label = { string = "" } })
end

local function set_play_icon(playing)
	if playing == last_play_state then
		return
	end
	last_play_state = playing
	local glyph = playing and icons.media.pause or icons.media.play
	local color = playing and colors.accent or colors.with_alpha(colors.accent, 0.45)
	playpause:set({ icon = { string = glyph, color = color } })
	popup_playpause:set({ icon = { string = glyph } })
end

local function set_label(text, faded, animate)
	local key = (faded and "f|" or "n|") .. text
	if key == last_label_state then
		return
	end
	last_label_state = key
	local color = faded and colors.with_alpha(colors.rosewater, faded) or colors.rosewater
	if animate then
		sbar.animate("tanh", 10, function()
			media:set({ label = { string = text, color = color } })
		end)
	else
		media:set({ label = { string = text, color = color } })
	end
end

local function set_idle()
	active_source = nil
	clear_track_info()
	set_play_icon(false)
	set_label("No media playing", 0.5, true)
end

local function set_track(title, artist, playing, source, artwork_url)
	local display = truncate(title .. (artist ~= "" and (" – " .. artist) or ""), MAX_LABEL_CHARS)

	active_source = source
	update_track_info(title, artist, source, artwork_url)
	set_play_icon(playing)
	set_label(display, not playing and 0.5 or false, true)
end

-- MediaRemote is system-wide: this covers every app and browser that publishes
-- a macOS Now Playing session, without maintaining a browser allowlist.
local function poll_system_media(fallback)
	sbar.exec("nowplaying-cli get playbackRate title artist", function(out)
		local rate_str, title, artist = out:match("([^\n]*)\n([^\n]*)\n([^\n]*)")
		local rate = tonumber(rate_str) or 0
		title = title and title:gsub("^%s*(.-)%s*$", "%1") or ""
		artist = artist and artist:gsub("^%s*(.-)%s*$", "%1") or ""
		if artist == "null" then
			artist = ""
		end

		if title ~= "" and title ~= "null" then
			set_track(title, artist, rate > 0, "system")
		else
			fallback()
		end
		poll_in_flight = false
	end)
end

local function poll()
	if poll_in_flight then
		return
	end
	poll_in_flight = true

	sbar.exec(CIDER_STATUS, function(out)
		local title, artist, playing, artwork_url = out:match("^([^\n]*)\n([^\n]*)\n([^\n]*)\n([^\n]*)")
		title = title or ""
		artist = artist or ""
		local cider_available = title ~= ""

		if cider_available and playing == "true" then
			set_track(title, artist, true, "cider", artwork_url)
			poll_in_flight = false
			return
		end

		poll_system_media(function()
			if cider_available then
				set_track(title, artist, false, "cider", artwork_url)
			else
				set_idle()
			end
		end)
	end)
end

local native_actions = {
	playpause = "togglePlayPause",
	previous = "previous",
	next = "next",
}

local function control_command(action)
	if active_source == "cider" then
		return CIDER_AUTH
			.. string.format(
				[[curl -fsS --max-time 2 -X POST -H "apptoken: $cider_token" -H "Content-Type: application/json" -d '{}' %q >/dev/null]],
				CIDER_URL .. "/" .. action
			)
	end
	return "nowplaying-cli " .. native_actions[action]
end

local function poll_after(action)
	sbar.exec(control_command(action), function()
		poll_in_flight = false
		poll()
		sbar.exec("sleep 0.4 && true", function()
			poll_in_flight = false
			poll()
		end)
	end)
end

local function toggle_popup()
	media:set({ popup = { drawing = "toggle" } })
end

media:subscribe({ "routine", "system_woke", "media_change" }, poll)
media:subscribe("mouse.clicked", toggle_popup)
artwork:subscribe("mouse.clicked", toggle_popup)

local function optimistic_toggle()
	if last_play_state ~= nil then
		local now_playing = not last_play_state
		set_play_icon(now_playing)
		if last_label_state then
			local text = last_label_state:sub(3)
			last_label_state = nil
			set_label(text, not now_playing and 0.45 or false, false)
		end
	end
	poll_after("playpause")
end

playpause:subscribe("mouse.clicked", optimistic_toggle)
popup_playpause:subscribe("mouse.clicked", optimistic_toggle)
popup_prev:subscribe("mouse.clicked", function()
	poll_after("previous")
end)
popup_next:subscribe("mouse.clicked", function()
	poll_after("next")
end)

media:subscribe("mouse.exited.global", function()
	media:set({ popup = { drawing = false } })
end)

poll()

utils.hover_lift(playpause, { height = 24, corner_radius = 7 })
utils.hover_lift(media, { height = 24, corner_radius = 7 })
utils.hover_lift(artwork, { height = 24, corner_radius = 5 })
