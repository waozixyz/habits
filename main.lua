-- Habits Tracker - Clean Automatic Reactivity Version
local Reactive = require("kryon.reactive")
local UI = require("kryon.dsl")

-- Smart DSL Components
local Column, Row, Text, Button, Input, TabGroup, TabBar, TabContent, TabPanel, mapArray, unpack =
  UI.Column, UI.Row, UI.Text, UI.Button, UI.Input, UI.TabGroup, UI.TabBar, UI.TabContent, UI.TabPanel, UI.mapArray, UI.unpack

-- Load kryon-plugin-storage
local Storage = require("storage")

-- Initialize storage once
Storage.init("habits")

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function getCurrentDate()
  return os.date("%Y-%m-%d")
end

local function formatMonth(year, month)
  return os.date("%B %Y", os.time({year=year, month=month, day=1}))
end

local function getDaysInMonth(year, month)
  local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
    return 29
  end
  return days[month]
end

local function getWeekday(year, month, day)
  local t = os.time({year=year, month=month, day=day})
  return tonumber(os.date("%w", t))
end

local function makeDate(year, month, day)
  return os.date("%Y-%m-%d", os.time({year=year, month=month, day=day}))
end

local function isDateInFuture(dateStr)
  if not dateStr or dateStr == "" then return false end
  local year, month, day = dateStr:match("(%d+)-(%d+)-(%d+)")
  if not year then return false end

  local targetTime = os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day)})
  local today = os.time({year=os.date("%Y"), month=os.date("%m"), day=os.date("%d")})
  return targetTime > today
end

-- ============================================================================
-- Persistence
-- ============================================================================

local function loadHabits()
  local today = getCurrentDate()

  local defaultHabits = {
    {name = "Meditation", createdAt = today, completions = {}},
    {name = "Exercise", createdAt = today, completions = {}},
    {name = "Reading", createdAt = today, completions = {}}
  }

  local stored = Storage.getItem("habits_data")
  if stored then
    local success, data = pcall(Storage.decode, stored)
    if success and data and data.habits then
      return data.habits
    end
  end

  return defaultHabits
end

local function saveHabits(habits)
  -- Use Reactive.toRaw to get the underlying data structure
  local rawHabits = Reactive.toRaw(habits)
  local data = {habits = rawHabits}
  local content = Storage.encode(data)
  Storage.setItem("habits_data", content)
end

-- ============================================================================
-- Reactive State - Clean and Simple!
-- ============================================================================

local state = Reactive.reactive({
  habits = loadHabits(),
  selectedHabit = 1,
  editingHabit = 0,
  displayedMonth = {
    year = tonumber(os.date("%Y")),
    month = tonumber(os.date("%m"))
  }
})

-- ============================================================================
-- Event Handlers - Dramatically Simplified!
-- ============================================================================

local function addNewHabit()
  table.insert(state.habits, {
    name = "New Habit",
    createdAt = getCurrentDate(),
    completions = {}
  })
  state.selectedHabit = #state.habits
  saveHabits(state.habits)
end

local function toggleHabitCompletion(habitIndex, dateStr)
  if not dateStr or dateStr == "" or isDateInFuture(dateStr) then
    return
  end

  local completions = state.habits[habitIndex].completions
  local oldValue = completions[dateStr] or false
  completions[dateStr] = not oldValue

  saveHabits(state.habits)
end

local function updateHabitName(habitIndex, newName)
  if state.habits[habitIndex] then
    state.habits[habitIndex].name = newName
    saveHabits(state.habits)
  end
end

local function navigateMonth(offset)
  local newMonth = state.displayedMonth.month + offset
  local newYear = state.displayedMonth.year

  if newMonth > 12 then
    newMonth = 1
    newYear = newYear + 1
  elseif newMonth < 1 then
    newMonth = 12
    newYear = newYear - 1
  end

  state.displayedMonth.month = newMonth
  state.displayedMonth.year = newYear
end

-- ============================================================================
-- Calendar Generation
-- ============================================================================

local function generateCalendarData(habit, year, month)
  local today = getCurrentDate()
  local todayYear, todayMonth, todayDay = today:match("(%d+)-(%d+)-(%d+)")
  todayYear, todayMonth, todayDay = tonumber(todayYear), tonumber(todayMonth), tonumber(todayDay)

  local daysInMonth = getDaysInMonth(year, month)
  local firstWeekday = getWeekday(year, month, 1)
  local startOffset = (firstWeekday + 6) % 7

  local days = {}

  -- Previous month padding
  local prevMonth = month - 1
  local prevYear = year
  if prevMonth == 0 then
    prevMonth = 12
    prevYear = prevYear - 1
  end
  local daysInPrevMonth = getDaysInMonth(prevYear, prevMonth)

  for i = 0, startOffset - 1 do
    local dayNum = daysInPrevMonth - startOffset + 1 + i
    table.insert(days, {
      dayNumber = dayNum,
      date = "",
      isCurrentMonth = false,
      isToday = false,
      isCompleted = false
    })
  end

  -- Current month days
  for d = 1, daysInMonth do
    local dateStr = makeDate(year, month, d)
    local isCompleted = habit.completions[dateStr] or false
    local isToday = (year == todayYear and month == todayMonth and d == todayDay)

    table.insert(days, {
      dayNumber = d,
      date = dateStr,
      isCurrentMonth = true,
      isToday = isToday,
      isCompleted = isCompleted
    })
  end

  -- Next month padding
  local nextMonthDays = 42 - #days
  for d = 1, nextMonthDays do
    table.insert(days, {
      dayNumber = d,
      date = "",
      isCurrentMonth = false,
      isToday = false,
      isCompleted = false
    })
  end

  return days
end

-- ============================================================================
-- Styling
-- ============================================================================

local function getDayStyle(day)
  local style = {
    backgroundColor = "#3d3d3d",
    color = "#ffffff"
  }

  if day.isCompleted then
    style.backgroundColor = "#4a90e2"
  elseif day.isToday then
    style.borderColor = "#4a90e2"
  elseif not day.isCurrentMonth then
    style.backgroundColor = "#2d2d2d"
  end

  return style
end

-- ============================================================================
-- UI Components
-- ============================================================================

local function buildHabitPanel(habit, habitIndex)
  local calendarDays = generateCalendarData(habit, state.displayedMonth.year, state.displayedMonth.month)

  -- Build calendar grid rows
  local calendarRows = {}
  for weekRow = 0, 5 do
    local rowChildren = {}
    for dayCol = 0, 6 do
      local dayIndex = weekRow * 7 + dayCol + 1
      local day = calendarDays[dayIndex]
      local style = getDayStyle(day)

      table.insert(rowChildren, Button {
        width = "40px",
        height = "40px",
        fontSize = 12,
        text = day.isCurrentMonth and tostring(day.dayNumber) or "",
        backgroundColor = style.backgroundColor,
        color = style.color,
        borderColor = style.borderColor,
        disabled = isDateInFuture(day.date) or not day.isCurrentMonth,
        onClick = function()
          toggleHabitCompletion(habitIndex, day.date)
        end
      })
    end
    table.insert(calendarRows, Row {
      gap = 5,
      unpack(rowChildren)
    })
  end

  -- Build main panel
  return TabPanel {
    backgroundColor = "#1a1a1a",
    padding = 30,

    -- Title row (editable)
    Row {
      alignItems = "center",
      gap = 10,

      state.editingHabit == habitIndex and Input {
        value = habit.name,
        onTextChange = function(newName)
          updateHabitName(habitIndex, newName)
        end,
        fontSize = 24,
        color = "#ffffff",
        backgroundColor = "#2d2d2d",
        width = "300px"
      } or Text {
        text = habit.name,
        color = "#ffffff",
        fontSize = 24
      },

      Button {
        text = state.editingHabit == habitIndex and "Done" or "Edit",
        onClick = function()
          state.editingHabit = state.editingHabit == habitIndex and 0 or habitIndex
        end,
        backgroundColor = "#4a90e2",
        color = "#ffffff",
        fontSize = state.editingHabit == habitIndex and nil or 14
      }
    },

    -- Month navigation
    Row {
      alignItems = "center",
      justifyContent = "space-between",

      Button {
        text = "<",
        onClick = function()
          navigateMonth(-1)
        end
      },

      Text {
        text = formatMonth(state.displayedMonth.year, state.displayedMonth.month),
        color = "#ffffff",
        fontSize = 24
      },

      Button {
        text = ">",
        onClick = function()
          navigateMonth(1)
        end
      }
    },

    -- Week day headers
    Row {
      gap = 5,
      unpack(mapArray({"M", "T", "W", "T", "F", "S", "S"}, function(dayName)
        return Button {
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

local function buildTabsAndPanels(habitsList)
  -- Map habits to tabs
  local tabs = mapArray(habitsList, function(habit, i)
    return UI.Tab {
      title = habit.name,
      backgroundColor = "#3d3d3d",
      activeBackgroundColor = "#4a90e2",
      textColor = "#ffffff",
      activeTextColor = "#ffffff",
      onClick = function()
        state.selectedHabit = i
      end
    }
  end)

  -- Add "+" button tab
  table.insert(tabs, UI.Tab {
    title = "+",
    width = "50px",
    backgroundColor = "#3d3d3d",
    onClick = addNewHabit
  })

  -- Map habits to panels using manual loop (mapArray has issues)
  local panels = {}
  for i, habit in ipairs(habitsList) do
    table.insert(panels, buildHabitPanel(habit, i))
  end

  return tabs, panels
end

-- ============================================================================
-- Main UI - Automatically Reactive!
-- ============================================================================

local function buildUI()
  local selected = state.selectedHabit
  local tabs, panels = buildTabsAndPanels(state.habits)

  return UI.Column({
    width = "800px",
    height = "600px",
    background = "#1a1a1a",
    windowTitle = "Habits",
    children = {
      UI.TabGroup({
        selectedIndex = selected - 1,
        backgroundColor = "#1a1a1a",
        children = {
          UI.TabBar({
            backgroundColor = "#2d2d2d",
            children = tabs
          }),
          UI.TabContent({
            backgroundColor = "#1a1a1a",
            children = panels
          })
        }
      })
    }
  })
end

-- ============================================================================
-- Create Reactive App - No Manual Computed Wrapper Needed!
-- ============================================================================

local runtime = require("kryon.runtime")

local app = runtime.createReactiveApp({
  root = buildUI,  -- Just pass the function - automatic reactivity!
  window = {
    width = 800,
    height = 600,
    title = "Habits"
  }
})

return app
