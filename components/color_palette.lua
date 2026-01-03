-- Color palette for habit themes
local COLORS = {
  {name = "Blue", hex = "#4a90e2"},
  {name = "Purple", hex = "#9b59b6"},
  {name = "Green", hex = "#27ae60"},
  {name = "Orange", hex = "#e67e22"},
  {name = "Pink", hex = "#e91e63"},
  {name = "Teal", hex = "#1abc9c"},
  {name = "Red", hex = "#e74c3c"},
  {name = "Indigo", hex = "#5c6bc0"},
  {name = "Amber", hex = "#f39c12"},
  {name = "Cyan", hex = "#00bcd4"}
}

local DEFAULT_COLOR = "#4a90e2"

-- Get a random color from the palette
local function getRandomColor()
  return COLORS[math.random(1, #COLORS)].hex
end

return {
  COLORS = COLORS,
  DEFAULT_COLOR = DEFAULT_COLOR,
  getRandomColor = getRandomColor
}
