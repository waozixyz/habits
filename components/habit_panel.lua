-- Individual habit panel component
-- Uses DateTime plugin for platform-independent date operations
local Calendar = require("components.calendar")
local ColorPicker = require("components.color_picker")
local DateTime = require("datetime")
local Reactive = require("kryon.reactive")

-- Helper to convert Lua table to JSON string for JavaScript
local function toJson(tbl)
  if type(tbl) ~= "table" then
    if type(tbl) == "string" then
      return '"' .. tbl:gsub('"', '\\"') .. '"'
    elseif type(tbl) == "boolean" then
      return tbl and "true" or "false"
    else
      return tostring(tbl)
    end
  end

  -- Check if array or object
  local isArray = #tbl > 0
  local parts = {}

  if isArray then
    for _, v in ipairs(tbl) do
      table.insert(parts, toJson(v))
    end
    return "[" .. table.concat(parts, ",") .. "]"
  else
    for k, v in pairs(tbl) do
      table.insert(parts, '"' .. tostring(k) .. '":' .. toJson(v))
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end
end

-- Helper function to build calendar row UI components from calendar data
local function buildCalendarRows(UI, rows, habit, habitColor, habitIndex, toggleHabitCompletion)
  local rowComponents = {}
  for rowIndex, weekRow in ipairs(rows) do
    local dayButtons = {}
    for dayIndex, day in ipairs(weekRow) do
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
    table.insert(rowComponents, UI.Row {
      gap = 5,
      unpack(dayButtons)
    })
  end
  return rowComponents
end

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
    elementId = "next-btn-" .. habitIndex,
    text = ">",
    backgroundColor = habitColor,
    color = "#ffffff",
    fontSize = 18,
    width = "40px",
    height = "40px",
    -- Static initial value - Reactive.effect handles updates
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

  -- 5. Calendar grid - ID assigned by JavaScript kryonInitCalendarContainers()
  local calendarContainerId = "calendar-" .. habitIndex

  -- Build initial calendar rows statically
  local initialRows = Calendar.generateCalendarRows(habit, state.displayedMonth.year, state.displayedMonth.month, habitColor)
  local initialRowComponents = buildCalendarRows(UI, initialRows, habit, habitColor, habitIndex, toggleHabitCompletion)

  -- Calendar container with custom element ID for JavaScript access
  local calendarGrid = UI.Column {
    elementId = calendarContainerId,
    gap = 0,
    unpack(initialRowComponents)
  }

  -- Watch displayedMonth and re-render calendar when it changes (web only)
  -- Use pcall to safely check for JS module availability (only on Fengari/web)
  local jsAvailable, js = pcall(require, "js")
  print("[Habits] JS module available: " .. tostring(jsAvailable) .. " for habit " .. habitIndex)

  if jsAvailable and js then
    print("[Habits] Registering Reactive.effect for calendar " .. calendarContainerId)
    local calendarInitialized = false
    Reactive.effect(function()
      -- Read dependencies to track them
      local year = state.displayedMonth.year
      local month = state.displayedMonth.month

      print("[Habits] Effect fired for " .. calendarContainerId .. ": " .. year .. "-" .. month .. " (initialized=" .. tostring(calendarInitialized) .. ")")

      -- Skip initial render (already rendered statically above)
      if not calendarInitialized then
        calendarInitialized = true
        print("[Habits] Skipping initial render for " .. calendarContainerId)
        return
      end

      print("[Habits] Re-rendering calendar " .. calendarContainerId .. " for " .. year .. "-" .. month)

      local window = js.global

      -- Update month label text
      local monthLabelId = "month-label-" .. habitIndex
      local monthLabel = window.document:querySelector("#" .. monthLabelId)
      if monthLabel then
        local formattedDate = DateTime.format({year=year, month=month, day=1}, "%B %Y")
        monthLabel.textContent = formattedDate
        print("[Habits] Updated month label to: " .. formattedDate)
      else
        print("[Habits] Month label not found: " .. monthLabelId)
      end

      -- Update next button disabled state
      local nextBtnId = "next-btn-" .. habitIndex
      local nextBtn = window.document:querySelector("#" .. nextBtnId)
      if nextBtn then
        local disabled = isCurrentMonth(year, month)
        nextBtn.disabled = disabled
        nextBtn.style.opacity = disabled and "0.5" or "1"
        nextBtn.style.cursor = disabled and "default" or "pointer"
        print("[Habits] Updated next button disabled: " .. tostring(disabled))
      else
        print("[Habits] Next button not found: " .. nextBtnId)
      end

      -- Generate new calendar data
      local rows = Calendar.generateCalendarRows(habit, year, month, habitColor)

      -- Convert to JSON and render calendar using app-defined renderer
      local rowsJson = toJson(rows)

      -- Check if a date is in the future
      local now = DateTime.now()
      local todayStr = string.format("%04d-%02d-%02d", now.year, now.month, now.day)

      -- Inline calendar rendering JavaScript (app-specific, not framework)
      local jsCode = string.format([[
        (function() {
          var container = document.getElementById('%s');
          if (!container) {
            console.warn('[Habits] Calendar container not found:', '%s');
            return;
          }
          var weeks = %s;
          var themeColor = '%s';
          var habitId = %d;

          function isDateInFuture(dateStr) {
            if (!dateStr) return true;
            var today = new Date('%s');
            today.setHours(0, 0, 0, 0);
            var date = new Date(dateStr);
            return date > today;
          }

          var html = '';
          weeks.forEach(function(week) {
            html += '<div class="row" style="display: flex; flex-direction: row; gap: 5px;">';
            week.forEach(function(day) {
              var bgColor = day.isCompleted ? themeColor :
                           (day.isCurrentMonth ? 'rgba(61, 61, 61, 1.00)' : 'rgba(45, 45, 45, 1.00)');
              var borderStyle = day.isToday && day.isCurrentMonth ?
                               'border: 2px solid ' + themeColor + ';' : '';
              var disabled = !day.isCurrentMonth || isDateInFuture(day.date);

              html += '<button class="button" style="background-color: ' + bgColor + '; color: rgba(255, 255, 255, 1.00); ' + borderStyle + ' width: 40px; height: 40px; font-size: 12px; border-radius: 4px; cursor: ' + (disabled ? 'default' : 'pointer') + ';" data-date="' + (day.date || '') + '" data-habit="' + habitId + '" data-is-completed="' + (day.isCompleted ? 'true' : 'false') + '" onclick="if(window.fengari)try{fengari.load(\'toggleHabitCompletion(' + habitId + ', \\x22' + (day.date || '') + '\\x22)\')();}catch(e){console.error(e);}" ' + (disabled ? 'disabled' : '') + '>' + (day.isCurrentMonth ? (day.dayNumber || '') : '') + '</button>';
            });
            html += '</div>';
          });

          container.innerHTML = html;
          console.log('[Habits] Re-rendered calendar', '%s', 'with', weeks.length, 'weeks');
        })();
      ]], calendarContainerId, calendarContainerId, rowsJson, habitColor, habitIndex, todayStr, calendarContainerId)

      window:eval(jsCode)
    end)
  else
    print("[Habits] JS module NOT available, calendar updates disabled")
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
        elementId = "month-label-" .. habitIndex,
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

    -- Calendar grid (ForEach component)
    calendarGrid
  }
end

return {
  buildHabitPanel = buildHabitPanel
}
