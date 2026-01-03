-- Individual habit panel component
local Calendar = require("components.calendar")
local ColorPicker = require("components.color_picker")

local function isCurrentMonth(displayedYear, displayedMonth)
  local currentYear = tonumber(os.date("%Y"))
  local currentMonth = tonumber(os.date("%m"))
  return displayedYear == currentYear and displayedMonth == currentMonth
end

local function buildHabitPanel(UI, state, editingState, toggleHabitCompletion, updateHabitName, navigateMonth, habit, habitIndex, updateHabitColor)
  local habitColor = habit.color or "#4a90e2"
  local calendarDays = Calendar.generateCalendarData(habit, state.displayedMonth.year, state.displayedMonth.month, habitColor)

  -- Build calendar grid rows
  local calendarRows = {}
  for weekRow = 0, 5 do
    local rowChildren = {}
    for dayCol = 0, 6 do
      local dayIndex = weekRow * 7 + dayCol + 1
      local day = calendarDays[dayIndex]
      local style = Calendar.getDayStyle(day, habitColor)

      table.insert(rowChildren, UI.Button {
        width = "40px",
        height = "40px",
        fontSize = 12,
        text = day.isCurrentMonth and tostring(day.dayNumber) or "",
        backgroundColor = style.backgroundColor,
        color = style.color,
        borderColor = style.borderColor,
        disabled = Calendar.isDateInFuture(day.date) or not day.isCurrentMonth,
        onClick = function()
          toggleHabitCompletion(habitIndex, day.date)
        end
      })
    end
    table.insert(calendarRows, UI.Row {
      gap = 5,
      unpack(rowChildren)
    })
  end

  -- Build main panel
  return UI.TabPanel {
    backgroundColor = "#1a1a1a",
    padding = 30,

    -- Title row (editable)
    UI.Row {
      alignItems = "center",
      gap = 10,

      state.editingHabit == habitIndex and UI.Input {
        value = editingState.name,  -- Use non-reactive temp state
        onTextChange = function(newName)
          editingState.name = newName  -- Update non-reactive state (no rebuild)
        end,
        fontSize = 24,
        color = "#ffffff",
        backgroundColor = "#2d2d2d",
        width = "300px"
      } or UI.Text {
        text = habit.name,
        color = "#ffffff",
        fontSize = 24
      },

      UI.Button {
        text = state.editingHabit == habitIndex and "Done" or "Edit",
        onClick = function()
          if state.editingHabit == habitIndex then
            -- Done: save the edited name
            updateHabitName(habitIndex, editingState.name)
            state.editingHabit = 0
          else
            -- Edit: copy current name to editing state
            editingState.name = habit.name
            state.editingHabit = habitIndex
          end
        end,
        backgroundColor = habitColor,
        color = "#ffffff",
        fontSize = state.editingHabit == habitIndex and nil or 14
      }
    },

    -- Month navigation
    UI.Row {
      alignItems = "center",
      justifyContent = "space-between",

      UI.Button {
        text = "<",
        backgroundColor = habitColor,
        color = "#ffffff",
        fontSize = 18,
        width = "40px",
        height = "40px",
        onClick = function()
          navigateMonth(-1)
        end
      },

      UI.Text {
        text = os.date("%B %Y", os.time({year=state.displayedMonth.year, month=state.displayedMonth.month, day=1})),
        color = "#ffffff",
        fontSize = 24
      },

      UI.Button {
        text = ">",
        backgroundColor = habitColor,
        color = "#ffffff",
        fontSize = 18,
        width = "40px",
        height = "40px",
        disabled = isCurrentMonth(state.displayedMonth.year, state.displayedMonth.month),
        onClick = function()
          navigateMonth(1)
        end
      }
    },

    -- Color picker
    ColorPicker.buildColorPicker(UI, state, habitIndex, updateHabitColor, habit),

    -- Week day headers
    UI.Row {
      gap = 5,
      unpack(UI.mapArray({"M", "T", "W", "T", "F", "S", "S"}, function(dayName)
        return UI.Button {
          text = dayName,
          width = "40px",
          height = "20px",
          backgroundColor = "#2d2d2d",
          fontSize = 10,
          disabled = true
        }
      end))
    },

    -- Calendar grid
    unpack(calendarRows)
  }
end

return {
  buildHabitPanel = buildHabitPanel
}
