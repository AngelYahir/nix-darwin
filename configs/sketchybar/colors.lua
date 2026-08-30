local function with_alpha(color, alpha)
  assert(type(color) == "number", "with_alpha expected a numeric color")
  if alpha > 1.0 or alpha < 0.0 then return color end
  return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

local function brighten(color, amount)
  assert(type(color) == "number", "brighten expected a numeric color")
  if amount <= 0.0 then return color end
  amount = math.min(amount, 1.0)

  local function lift(channel)
    return math.floor(channel + (255 - channel) * amount + 0.5)
  end

  local alpha = color & 0xff000000
  local red = lift((color >> 16) & 0xff)
  local green = lift((color >> 8) & 0xff)
  local blue = lift(color & 0xff)
  return alpha | (red << 16) | (green << 8) | blue
end

return {
  -- Catppuccin Mocha
  rosewater = 0xfff5e0dc,
  flamingo = 0xfff2cdcd,
  pink = 0xfff5c2e7,
  mauve = 0xffcba6f7,
  red = 0xfff38ba8,
  maroon = 0xffeba0ac,
  peach = 0xfffab387,
  yellow = 0xfff9e2af,
  green = 0xffa6e3a1,
  teal = 0xff94e2d5,
  sky = 0xff89dceb,
  sapphire = 0xff74c7ec,
  blue = 0xff89b4fa,
  lavender = 0xffb4befe,
  text = 0xffcdd6f4,
  subtext1 = 0xffbac2de,
  subtext0 = 0xffa6adc8,
  overlay2 = 0xff9399b2,
  overlay1 = 0xff7f849c,
  overlay0 = 0xff6c7086,
  surface2 = 0xff585b70,
  surface1 = 0xff45475a,
  surface0 = 0xff313244,
  base = 0xff1e1e2e,
  mantle = 0xff181825,
  crust = 0xff11111b,
  transparent = 0x00000000,

  accent = 0xffcba6f7,
  panel = 0xf2313244,
  hover = 0x1acdd6f4,
  hover_amount = 0.12,
  space_active = 0xffcba6f7,
  space_active_fg = 0xff1e1e2e,

  bar = {
    bg = 0x00000000,
  },
  popup = {
    bg = 0xf21e1e2e,
    border = 0xff45475a,
  },

  with_alpha = with_alpha,
  brighten = brighten,
}
