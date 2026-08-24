local clock = sbar.add("item", "clock", {
  position = "right",

  icon = {
    drawing = false,
  },

  label = {
    string = "--:--",
  },

  update_freq = 10,
})

clock:subscribe("routine", function()
  sbar.exec("date '+%H:%M'", function(result)
    clock:set({
      label = result,
    })
  end)
end)