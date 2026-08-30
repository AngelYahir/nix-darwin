local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")
local backend = require("items.spaces_a")

local MAX_SLOTS = 10
local pill_height = 19
local pill_padding = {
	active_empty = 8,
	active_icons = 8,
}
local inactive_number_color = colors.text
local japanese_numbers = {
	["1"] = "一",
	["2"] = "二",
	["3"] = "三",
	["4"] = "四",
	["5"] = "五",
	["6"] = "六",
	["7"] = "七",
	["8"] = "八",
	["9"] = "九",
	["10"] = "十",
}

local slots = {}
local slot_ws = {}
local slot_state = {}
local slot_drawn = {}
local slot_base_color = {}
local slot_hovered = {}
local update_in_flight_at = 0
local update_dirty = false
local LOCK_TIMEOUT_S = 3

local function build_space_set(icons, selected, ws_label)
	local has_icons = icons ~= ""
	local should_draw = selected or has_icons
	local has_number = ws_label ~= nil and ws_label ~= ""

	if not selected then
		return {
			drawing = should_draw,
			label = {
				string = "",
				drawing = false,
				padding_left = 0,
				padding_right = 0,
			},
			icon = {
				string = has_number and ws_label or "",
				font = {
					family = settings.font.text,
					style = settings.font.style_map["Semibold"],
					size = 12,
				},
				color = inactive_number_color,
				drawing = has_number,
				width = pill_height,
				align = "center",
				padding_left = 0,
				padding_right = 0,
				y_offset = 0,
			},
			background = {
				color = colors.surface2,
			},
		}
	end

	local pad
	if has_icons then
		pad = pill_padding.active_icons
	else
		pad = pill_padding.active_empty
	end

	return {
		drawing = true,
		label = {
			string = "",
			drawing = false,
			padding_left = 0,
			padding_right = 0,
		},
		icon = {
			string = has_icons and icons or (has_number and ws_label or ""),
			font = {
				family = has_icons and settings.font.icons or settings.font.text,
				style = has_icons and "Regular" or settings.font.style_map["Semibold"],
				size = has_icons and 14.0 or 12,
			},
			color = colors.space_active_fg,
			drawing = has_icons or has_number,
			width = "dynamic",
			align = "center",
			padding_left = pad,
			padding_right = pad,
			y_offset = 0,
		},
		background = {
			color = colors.space_active,
		},
	}
end

local function update_all_spaces()
	local now = os.time()
	if update_in_flight_at ~= 0 and (now - update_in_flight_at) < LOCK_TIMEOUT_S then
		update_dirty = true
		return
	end
	update_in_flight_at = now

	sbar.exec(backend.fetch_state_cmd(), function(output)
		update_in_flight_at = 0

		local workspace_icons = {}
		local seen = {}
		local workspaces = {}
		local focused = ""
		local section = 1

		for line in output:gmatch("[^\n]+") do
			if line == "---" then
				section = section + 1
			elseif section == 1 then
				local ws, app = line:match("^(.-)|(.+)$")
				if ws then
					if not workspace_icons[ws] then
						workspace_icons[ws] = ""
						seen[ws] = {}
					end
					local lookup = app_icons[app]
					local icon = ((lookup == nil) and app_icons["default"] or lookup)
					if not seen[ws][icon] then
						if workspace_icons[ws] == "" then
							workspace_icons[ws] = icon
						else
							workspace_icons[ws] = workspace_icons[ws] .. " " .. icon
						end
						seen[ws][icon] = true
					end
				end
			elseif section == 2 then
				workspaces[#workspaces + 1] = line:gsub("%s+", "")
			else
				focused = line:gsub("%s+", "")
			end
		end

		-- Keep the current state while Aerospace is restarting.
		if #workspaces == 0 then
			if update_dirty then
				update_dirty = false
				update_all_spaces()
			end
			return
		end

		for i = 1, MAX_SLOTS do
			local ws = workspaces[i]
			if slot_ws[i] ~= ws then
				slot_ws[i] = ws
				slot_state[i] = nil
				if ws then
					slots[i]:set({ click_script = backend.click_cmd(ws) })
				else
					slots[i]:set({ drawing = false })
					slot_drawn[i] = false
				end
			end
		end

		local changed = {}
		for i = 1, MAX_SLOTS do
			local ws = slot_ws[i]
			if ws then
				local icons = workspace_icons[ws] or ""
				local selected = ws == focused
				local display_label = backend.display_label(ws)
				local key = (selected and "1|" or "0|") .. icons
				if slot_state[i] ~= key then
					local was_drawn = slot_drawn[i] or false
					local now_drawn = selected or icons ~= ""
					slot_state[i] = key
					slot_drawn[i] = now_drawn
					changed[#changed + 1] = {
						slot = i,
						space = slots[i],
						icons = icons,
						selected = selected,
						label = japanese_numbers[display_label] or display_label,
						drawing_flipped = was_drawn ~= now_drawn,
					}
				end
			end
		end

		if #changed > 0 then
			local to_animate = {}
			for _, c in ipairs(changed) do
				local props = build_space_set(c.icons, c.selected, c.label)

				local base = props.background.color
				slot_base_color[c.slot] = base
				local shown = slot_hovered[c.slot] and colors.brighten(base, colors.hover_amount) or base

				if c.drawing_flipped then
					props.background.color = shown
					c.space:set(props)
				else
					props.background = nil
					c.space:set(props)
					to_animate[#to_animate + 1] = { space = c.space, color = shown }
				end
			end
			if #to_animate > 0 then
				sbar.animate("tanh", 8, function()
					for _, t in ipairs(to_animate) do
						t.space:set({ background = { color = t.color } })
					end
				end)
			end
		end

		if update_dirty then
			update_dirty = false
			update_all_spaces()
		end
	end)
end

for i = 1, MAX_SLOTS do
	local space = sbar.add("item", "space.slot." .. i, {
		icon = {
			font = { family = settings.font.text, style = settings.font.style_map["Semibold"], size = 12 },
			string = "",
			color = colors.text,
			padding_left = 9,
			padding_right = 9,
			y_offset = 0,
			drawing = true,
		},
		label = { drawing = false },
		background = {
			color = colors.surface2,
			corner_radius = math.ceil(pill_height / 2),
			height = pill_height,
		},
		padding_left = 6,
		padding_right = 0,
		drawing = false,
	})

	local index = i
	slot_base_color[i] = colors.surface2
	space:subscribe("mouse.entered", function()
		slot_hovered[index] = true
		space:set({
			background = { color = colors.brighten(slot_base_color[index], colors.hover_amount) },
		})
	end)
	space:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
		slot_hovered[index] = false
		space:set({ background = { color = slot_base_color[index] } })
	end)

	slots[i] = space
end

sbar.add("item", "spaces.right_pad", {
	width = 3,
	icon = { drawing = false },
	label = { drawing = false },
	background = { drawing = false },
})

local observer = sbar.add("item", {
	drawing = false,
	updates = true,
	update_freq = 10,
})

local subscribed_events = { "routine" }
for _, ev in ipairs(backend.events) do
	subscribed_events[#subscribed_events + 1] = ev
end
observer:subscribe(subscribed_events, function()
	update_all_spaces()
end)

update_all_spaces()

return slots
