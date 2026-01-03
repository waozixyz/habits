-- Color picker component for habit themes
local ColorPalette = require("components.color_palette")

local function buildColorPicker(UI, state, habitIndex, updateHabitColor, habit)
  local habitColor = habit.color or ColorPalette.DEFAULT_COLOR

  -- Build color swatch buttons
  local colorButtons = {}
  for i, colorEntry in ipairs(ColorPalette.COLORS) do
    local isSelected = habitColor == colorEntry.hex

    table.insert(colorButtons, UI.Button {
      width = "32px",
      height = "32px",
      backgroundColor = colorEntry.hex,
      borderColor = isSelected and "#ffffff" or "#1a1a1a",
      borderWidth = isSelected and 3 or 1,
      borderRadius = isSelected and 16 or 8,
      onClick = function()
        updateHabitColor(habitIndex, colorEntry.hex)
      end
    })
  end

  -- Layout: 2 rows of 5 colors
  local firstRow = {}
  local secondRow = {}

  for i, button in ipairs(colorButtons) do
    if i <= 5 then
      table.insert(firstRow, button)
    else
      table.insert(secondRow, button)
    end
  end

  return UI.Column {
    gap = 8,
    marginTop = 20,

    UI.Text {
      text = "Theme Color",
      color = "#aaaaaa",
      fontSize = 14
    },

    UI.Row {
      gap = 8,
      unpack(firstRow)
    },

    UI.Row {
      gap = 8,
      unpack(secondRow)
    }
  }
end

return {
  buildColorPicker = buildColorPicker
}
