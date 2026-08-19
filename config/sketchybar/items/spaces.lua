local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}

-- Japanese numbers mapping
local japanese_numbers = {
  [1] = "一",
  [2] = "二", 
  [3] = "三",
  [4] = "四",
  [5] = "五",
  [6] = "六",
  [7] = "七",
  [8] = "八",
  [9] = "九",
  [10] = "十"
}

for i = 1, 10, 1 do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    icon = {
      font = { family = settings.font.numbers },
      string = japanese_numbers[i],
      padding_left = 12,
      padding_right = 12,
      color = colors.mauve,
      highlight_color = colors.lavender,
    },
    label = {
      padding_right = 18,
      padding_left = 8,
      color = colors.mauve,
      highlight_color = colors.lavender,
      font = "sketchybar-app-font:Regular:14.0",
      y_offset = -1,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.base,
      border_width = 1,
      height = 28,
      border_color = colors.black,
    },
    popup = { background = { border_width = 5, border_color = colors.black } }
  })

  spaces[i] = space

  -- Single item bracket for space items to achieve double border on highlight
  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    }
  })

  -- Padding space
  sbar.add("space", "space.padding." .. i, {
    space = i,
    script = "",
    width = settings.group_paddings,
  })

  local space_popup = sbar.add("item", {
    position = "popup." .. space.name,
    padding_left= 5,
    padding_right= 0,
    background = {
      drawing = true,
      image = {
        corner_radius = 9,
        scale = 0.2
      }
    }
  })

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    local color = selected and colors.grey or colors.bg2
    space:set({
      icon = { 
        highlight = selected,
        padding_left = selected and 12 or 12,
        padding_right = selected and 4 or 12,
      },
      label = { 
        highlight = selected,
        drawing = selected  -- Only show label (app icons) when selected
      },
      background = { border_color = selected and colors.lavender or colors.bg2 }
    })
    space_bracket:set({
      background = { border_color = selected and colors.lavender or colors.bg2 }
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      local op = (env.BUTTON == "right") and "--destroy" or "--focus"
      sbar.exec("yabai -m space " .. op .. " " .. env.SID)
    end
  end)

  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)
end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})



space_window_observer:subscribe("space_windows_change", function(env)
  local icon_line = ""
  local no_app = true
  for app, count in pairs(env.INFO.apps) do
    no_app = false
    local lookup = app_icons[app]
    local icon = ((lookup == nil) and app_icons["Default"] or lookup)
    icon_line = icon_line .. icon .. " "
  end

  if (no_app) then
    icon_line = " —"
  end
  sbar.animate("tanh", 10, function()
    spaces[env.INFO.space]:set({ label = icon_line })
  end)
end)





