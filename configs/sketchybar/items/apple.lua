local icons = require("icons")
local utils = require("utils")
local colors = require("colors")

local apple = sbar.add("item", "apple.logo", {
    position = "left",
    background = {
        image = {
            string = "./assets/sakura.png",
            scale = 0.004,
        },
    },

    label = { drawing = false },
    padding_left = 10,
    padding_right = 5,
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0",
})

sbar.add("item", {
    position = "left",
    width = 10,
    icon = {
        string = "|",
        font = {
            size = 16.0
        },
        color = colors.with_alpha(colors.white, 0.3),
        y_offset = 1,
    }
})

utils.hover_lift(apple, {height = 22, corner_radius = 11})