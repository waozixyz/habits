-- Color picker component for habit themes (Modal version)
local ColorPalette = require("components.color_palette")

local function buildColorPicker(UI, state, habitIndex, updateHabitColor, habit)
  local habitColor = habit.color or ColorPalette.DEFAULT_COLOR

  -- Build color swatch buttons for modal
  local colorButtons = {}
  for i, colorEntry in ipairs(ColorPalette.COLORS) do
    local isSelected = habitColor == colorEntry.hex

    table.insert(colorButtons, UI.Button {
      width = "40px",
      height = "40px",
      backgroundColor = colorEntry.hex,
      borderColor = isSelected and "#ffffff" or "transparent",
      borderWidth = isSelected and 3 or 0,
      borderRadius = 8,
      onClick = function()
        updateHabitColor(habitIndex, colorEntry.hex)
        state.showColorPicker = false  -- Close modal after selection
      end
    })
  end

  return UI.Column {
    gap = 8,
    marginTop = 20,

    -- Single button showing current color
    UI.Row {
      alignItems = "center",
      gap = 12,

      UI.Text {
        text = "Theme Color",
        color = "#aaaaaa",
        fontSize = 14
      },

      UI.Button {
        width = "60px",
        height = "32px",
        backgroundColor = habitColor,
        borderRadius = 8,
        onClick = function()
          state.showColorPicker = true
        end
      }
    },

    -- Color picker modal
    UI.Modal {
      isOpen = state.showColorPicker,
      onClose = function()
        state.showColorPicker = false
      end,
      title = "Choose Theme Color",
      width = "300px",
      height = "200px",
      backgroundColor = "#2d2d2d",
      borderRadius = 12,

      -- Color grid (2 rows of 5)
      UI.Column {
        gap = 12,
        alignItems = "center",
        justifyContent = "center",

        UI.Row {
          gap = 8,
          unpack({colorButtons[1], colorButtons[2], colorButtons[3], colorButtons[4], colorButtons[5]})
        },

        UI.Row {
          gap = 8,
          unpack({colorButtons[6], colorButtons[7], colorButtons[8], colorButtons[9], colorButtons[10]})
        }
      }
    }
  }
end

return {
  buildColorPicker = buildColorPicker
}
