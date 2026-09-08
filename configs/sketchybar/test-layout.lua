-- Run with Lua 5.4+: lua configs/sketchybar/test-layout.lua
local root = arg[0]:match("^(.*)/") or "."
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path

for _, module in ipairs({
	"items.apple", "items.spaces", "items.widgets.battery", "items.widgets.volume",
	"items.widgets.wifi", "items.widgets.bluetooth",
}) do
	package.loaded[module] = true
end

local file = assert(io.open(root .. "/settings.lua"))
local source = file:read("*a")
file:close()

for _, notch in ipairs({ true, false }) do
	local config = source:gsub("local notch = %a+", "local notch = " .. tostring(notch))
	package.loaded.settings = assert(load(config))()
	for _, module in ipairs({ "items", "items.media", "items.weather", "items.calendar" }) do
		package.loaded[module] = nil
	end
	local items, sides = {}, {}
	sbar = {
		exec = function() end,
		add = function(kind, name, properties, options)
			assert(not items[name], "duplicate item: " .. name)
			local item = { properties = options or properties, members = kind == "bracket" and properties }
			function item:set(values)
				for key, value in pairs(values) do self.properties[key] = value end
			end
			function item:subscribe() end
			items[name] = item
			if kind == "item" then
				local side = properties.position
				sides[side] = sides[side] or {}
				table.insert(sides[side], name)
			end
			return item
		end,
	}
	require("items")
	local left = items["center.media.spectrum.left"].properties
	local right = items["center.media.spectrum.right"].properties
	assert(left.drawing == false and right.drawing == false)
	if notch then
		assert(sides.q[1] == "center.media.spectrum.left")
		assert(sides.e[1] == "center.media.spectrum.right")
		assert(sides.e[2] == "widgets.weather")
		for _, spectrum in ipairs({ left, right }) do
			assert(spectrum.width == "dynamic", "capsule must reserve its full text width and padding")
			assert(spectrum.background.corner_radius == spectrum.background.height / 2)
			assert(spectrum.padding_left == 8 and spectrum.padding_right == 8)
			assert(spectrum.label.padding_left == spectrum.label.padding_right)
		end
		assert(table.concat(items["bracket.media"].members, ",") == "center.media.playpause,center.media.artwork,center.media")
		assert(table.concat(items["bracket.info"].members, ",") == "widgets.weather,widgets.date,widgets.time")
	else
		assert(sides.center[1] == "center.media.spectrum.left")
		assert(sides.center[#sides.center] == "center.media.spectrum.right")
		assert(left.padding_left == 1 and right.padding_right == 1)
		assert(#items["bracket.media"].members == 4 and not items["bracket.info"])
	end
end
print("SketchyBar layout OK (notch on/off)")
