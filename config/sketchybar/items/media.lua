local icons = require("icons")
local colors = require("colors")

local whitelist = { ["Spotify"] = true,
                    ["Music"] = true,
                    ["Música"] = true  -- Music app in Spanish
                  };

local media_cover = sbar.add("item", {
  position = "right",
  background = {
    image = {
      string = "media.artwork",
      scale = 0.85,
    },
    color = colors.transparent,
  },
  label = { drawing = false },
  icon = { drawing = false },
  drawing = false,
  updates = true,
  popup = {
    align = "center",
    horizontal = true,
  }
})

local media_artist = sbar.add("item", {
  position = "right",
  drawing = false,
  padding_left = 1,
  padding_right = 0,
  width = 0,
  icon = { drawing = false },
  label = {
    width = "dynamic",
    font = { size = 9 },
    color = colors.with_alpha(colors.white, 0.6),
    max_chars = 18,
    y_offset = 6,
    scroll_texts = false,
  },
})

local media_title = sbar.add("item", {
  position = "right",
  drawing = false,
  padding_left = 1,
  padding_right = 0,
  icon = { drawing = false },
  label = {
    font = { size = 11 },
    width = "dynamic",
    max_chars = 16,
    y_offset = -6,
    scroll_texts = true,
  },
})

sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.back },
  label = { drawing = false },
  click_script = "media-control previous-track",
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  click_script = "media-control toggle-play-pause",
})
sbar.add("item", {
  position = "popup." .. media_cover.name,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  click_script = "media-control next-track",
})

-- No animation needed, text always visible

-- Function to update media info using media-control
local function update_media()
  sbar.exec("media-control get | jq -r '.artist // empty, .title // empty, .bundleIdentifier // empty, .playing // false' && media-control get | jq -r '.artworkData' | base64 -d > /tmp/sketchybar_artwork.jpg 2>/dev/null", function(result)
    if result and result ~= "" then
      local lines = {}
      for line in result:gmatch("[^\r\n]+") do
        if line ~= "" and line ~= "null" then
          table.insert(lines, line)
        end
      end
      
      if #lines >= 4 then
        local artist = lines[1]
        local title = lines[2] 
        local app = lines[3]
        local playing = lines[4] == "true"
        
        -- Extract app name from bundle identifier
        local app_name = app:match("%.([^%.]+)$") or app
        if app_name then
          app_name = app_name:gsub("^%l", string.upper) -- Capitalize first letter
        end
        
        local drawing = playing and app_name and (app_name == "Music" or app_name == "Spotify")
        
        if drawing then
          -- Show artwork only
          media_cover:set({ 
            drawing = true,
            label = { drawing = false },
            background = {
              image = {
                string = "/tmp/sketchybar_artwork.jpg",
                scale = 0.05,
              }
            }
          })
          
          -- Show artist (top, fixed)
          media_artist:set({ 
            drawing = true, 
            label = { 
              string = artist or "Unknown Artist"
            }
          })
          
          -- Show title (bottom, scrollable)
          media_title:set({ 
            drawing = true, 
            label = { 
              string = title or "Unknown Title"
            }
          })
        else
          media_cover:set({ drawing = false, popup = { drawing = false } })
          media_artist:set({ drawing = false })
          media_title:set({ drawing = false })
        end
      else
        -- No media playing or insufficient data
        media_cover:set({ drawing = false, popup = { drawing = false } })
        media_artist:set({ drawing = false })
        media_title:set({ drawing = false })
      end
    else
      -- No media info available
      media_cover:set({ drawing = false, popup = { drawing = false } })
      media_artist:set({ drawing = false })
      media_title:set({ drawing = false })
    end
  end)
end

-- Update media info every 2 seconds
sbar.add("event", "media_update")
sbar.exec("(while true; do sleep 2; sketchybar --trigger media_update 2>/dev/null || break; done) &")

media_cover:subscribe("media_update", update_media)

-- Mouse events removed - text always visible

media_cover:subscribe("mouse.clicked", function(env)
  media_cover:set({ popup = { drawing = "toggle" }})
end)

media_title:subscribe("mouse.exited.global", function(env)
  media_cover:set({ popup = { drawing = false }})
end)
