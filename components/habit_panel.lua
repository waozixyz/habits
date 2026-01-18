-- Individual habit panel component
-- Uses DateTime plugin for platform-independent date operations
local Calendar = require("components.calendar")
local ColorPicker = require("components.color_picker")
local DateTime = require("datetime")


local function isCurrentMonth(displayedYear, displayedMonth)
  local now = DateTime.now()
  return displayedYear == now.year and displayedMonth == now.month
end

local function buildHabitPanel(UI, state, editingState, toggleHabitCompletion, updateHabitName, navigateMonth, habit, habitIndex, updateHabitColor, deleteHabit)
  local habitColor = habit.color or "#4a90e2"

  -- IMPORTANT: Build components in the SAME ORDER they appear in the return statement
  -- This ensures handler registration order matches KIR tree order

  -- 1. Title row components (Edit button)
  local editButton = UI.Button {
    text = state.editingHabit == habitIndex and "Done" or "Edit",
    onClick = function()
      print("[Habits] Edit button clicked for habit " .. habitIndex)
      if state.editingHabit == habitIndex then
        updateHabitName(habitIndex, editingState.name)
        state.editingHabit = 0
      else
        editingState.name = habit.name
        state.editingHabit = habitIndex
      end
    end,
    backgroundColor = habitColor,
    color = "#ffffff",
    fontSize = state.editingHabit == habitIndex and nil or 14
  }

  -- Delete button (only show when editing)
  local deleteButton = state.editingHabit == habitIndex and UI.Button {
    text = "Delete",
    onClick = function()
      print("[Habits] Delete button clicked for habit " .. habitIndex)
      deleteHabit(habitIndex)
    end,
    backgroundColor = "#e74c3c",
    color = "#ffffff",
    fontSize = 14
  } or nil

  -- 2. Navigation buttons (< and >)
  local prevButton = UI.Button {
    text = "<",
    backgroundColor = habitColor,
    color = "#ffffff",
    fontSize = 18,
    width = "40px",
    height = "40px",
    onClick = function()
      print("[Habits] Prev month button clicked")
      navigateMonth(-1)
    end
  }

  local nextButton = UI.Button {
    text = ">",
    backgroundColor = habitColor,
    color = "#ffffff",
    fontSize = 18,
    width = "40px",
    height = "40px",

    disabled = isCurrentMonth(state.displayedMonth.year, state.displayedMonth.month),
    onClick = function()
      print("[Habits] Next month button clicked")
      navigateMonth(1)
    end
  }

  -- 3. Color picker (has its own buttons)
  local colorPicker = ColorPicker.buildColorPicker(UI, state, habitIndex, updateHabitColor, habit)

  -- 4. Week day headers (disabled buttons, but still need to be in order)
  local weekHeaders = UI.mapArray({"M", "T", "W", "T", "F", "S", "S"}, function(dayName)
    return UI.Button {
      text = dayName,
      width = "40px",
      height = "20px",
      backgroundColor = "#2d2d2d",
      fontSize = 10,
      disabled = true
    }
  end)


  -- Calendar grid with dynamic binding for automatic reactivity
  local function buildCalendarRows()
    local rows = Calendar.generateCalendarRows(habit, state.displayedMonth.year, state.displayedMonth.month, habitColor)
    local components = {}
    for _, weekRow in ipairs(rows) do
      local dayButtons = {}
      for _, day in ipairs(weekRow) do
        local style = Calendar.getDayStyle(day, habitColor)
        local dateStr = day.date
        table.insert(dayButtons, UI.Button {
          width = "40px",
          height = "40px",
          fontSize = 12,
          text = day.isCurrentMonth and tostring(day.dayNumber) or "",
          backgroundColor = style.backgroundColor,
          color = style.color,
          borderColor = style.borderColor,
          disabled = Calendar.isDateInFuture(day.date) or not day.isCurrentMonth,
          onClick = function()
            toggleHabitCompletion(habitIndex, dateStr)
          end
        })
      end
      table.insert(components, UI.Row { gap = 5, unpack(dayButtons) })
    end
    return UI.Column {
      gap = 0,
      unpack(components)
    }
  end

  -- Build main panel using pre-built components
  return UI.TabPanel {
    backgroundColor = "#1a1a1a",
    padding = 30,

    -- Title row (editable)
    UI.Row {
      alignItems = "center",
      gap = 10,

      state.editingHabit == habitIndex and UI.Input {
        value = editingState.name,
        onTextChange = function(newName)
          editingState.name = newName
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

      editButton,

      deleteButton
    },

    -- Month navigation
    UI.Row {
      alignItems = "center",
      justifyContent = "space-between",

      prevButton,

      UI.Text {
        -- Dynamic binding - function is evaluated at runtime when state changes
        text = function() return DateTime.format({year=state.displayedMonth.year, month=state.displayedMonth.month, day=1}, "%B %Y") end,
        color = "#ffffff",
        fontSize = 24
      },

      nextButton
    },

    -- Color picker
    colorPicker,

    -- Week day headers
    UI.Row {
      gap = 5,
      unpack(weekHeaders)
    },

    -- Calendar grid (dynamic binding for automatic reactivity)
    function() return buildCalendarRows() end
  }
end

return {
  buildHabitPanel = buildHabitPanel
}
