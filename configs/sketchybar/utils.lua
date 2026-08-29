local colors = require("colors")

local M = {}

local LIFT_HEIGHT = 24
local LIFT_RADIUS = 12

local function on_hover(item, apply)
	item:subscribe("mouse.entered", function()
		apply(true)
	end)
	item:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
		apply(false)
	end)
end

function M.hover_lift(item, opts)
	opts = opts or {}
	local height = opts.height or LIFT_HEIGHT
	local radius = opts.corner_radius or LIFT_RADIUS

	on_hover(item, function(on)
		item:set({
			background = {
				drawing = true,
				color = on and colors.hover or colors.transparent,
				height = height,
				corner_radius = radius,
			},
		})
	end)
end

-- base is the item's normal background colour; hover lifts it toward white.
function M.hover_brighten(item, base)
	local lit = colors.brighten(base, colors.hover_amount)

	on_hover(item, function(on)
		item:set({ background = { drawing = true, color = on and lit or base } })
	end)
end

return M