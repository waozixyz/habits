-- Habits Tracker - Lua version
local Reactive = require("kryon.reactive")
local UI = require("kryon.dsl")

-- Load kryon-plugin-storage
local Storage = require("storage")

-- Initialize storage once
Storage.init("habits")

-- Helper functions for date handling
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
  -- Returns 0=Sunday, 1=Monday, ..., 6=Saturday
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

local function isSameDay(dateStr)
  if not dateStr or dateStr == "" then return false end
  return dateStr == getCurrentDate()
end

-- Habits persistence using kryon-plugin-storage

local function loadHabits()
  local today = getCurrentDate()

  -- Default habits
  local defaultHabits = {
    {name = "Meditation", createdAt = today, completions = {}},
    {name = "Exercise", createdAt = today, completions = {}},
    {name = "Reading", createdAt = today, completions = {}}
  }

  -- Try to load from storage
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
  local data = {habits = habits}
  local content = Storage.encode(data)
  Storage.setItem("habits_data", content)
  -- Auto-save happens automatically!
end

-- Calendar generation
local function generateCalendarData(habit, year, month)
  local today = getCurrentDate()
  local todayYear, todayMonth, todayDay = today:match("(%d+)-(%d+)-(%d+)")
  todayYear, todayMonth, todayDay = tonumber(todayYear), tonumber(todayMonth), tonumber(todayDay)

  local daysInMonth = getDaysInMonth(year, month)
  local firstWeekday = getWeekday(year, month, 1)
  -- Convert to Monday=0 format
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

-- Reactive state
local habits = Reactive.state(loadHabits())
local selectedHabit = Reactive.state(1) -- Lua is 1-indexed
local editingHabit = Reactive.state(0) -- 0 means not editing
local displayedMonth = Reactive.state({
  year = tonumber(os.date("%Y")),
  month = tonumber(os.date("%m"))
})

-- Event handlers
local function addNewHabit()
  local currentHabits = habits:get()
  table.insert(currentHabits, {
    name = "New Habit",
    createdAt = getCurrentDate(),
    completions = {}
  })
  habits:set(currentHabits)
  selectedHabit:set(#currentHabits)
  saveHabits(currentHabits)
end

local function toggleHabitCompletion(habitIndex, dateStr)
  if not dateStr or dateStr == "" or isDateInFuture(dateStr) then
    return
  end

  local currentHabits = habits:get()
  local habit = currentHabits[habitIndex]
  if habit then
    habit.completions[dateStr] = not (habit.completions[dateStr] or false)
    habits:set(currentHabits)
    saveHabits(currentHabits)
  end
end

local function updateHabitName(habitIndex, newName)
  local currentHabits = habits:get()
  if currentHabits[habitIndex] then
    currentHabits[habitIndex].name = newName
    habits:set(currentHabits)
    saveHabits(currentHabits)
  end
end

local function navigateMonth(offset)
  local current = displayedMonth:get()
  local newMonth = current.month + offset
  local newYear = current.year

  if newMonth > 12 then
    newMonth = 1
    newYear = newYear + 1
  elseif newMonth < 1 then
    newMonth = 12
    newYear = newYear - 1
  end

  displayedMonth:set({year = newYear, month = newMonth})
end

-- Style helper
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

-- Build UI
local function buildHabitPanel(habit, habitIndex)
  local currentMonth = displayedMonth:get()
  local calendarDays = generateCalendarData(habit, currentMonth.year, currentMonth.month)

  local children = {}

  -- Title row (editable)
  local titleRow = {}
  if editingHabit:get() == habitIndex then
    table.insert(titleRow, UI.Input({
      value = habit.name,
      onTextChange = function(newName)
        updateHabitName(habitIndex, newName)
      end,
      fontSize = 24,
      color = "#ffffff",
      backgroundColor = "#2d2d2d",
      width = "300px"
    }))
    table.insert(titleRow, UI.Button({
      text = "Done",
      onClick = function()
        editingHabit:set(0)
      end,
      backgroundColor = "#4a90e2",
      color = "#ffffff"
    }))
  else
    table.insert(titleRow, UI.Text({
      text = habit.name,
      color = "#ffffff",
      fontSize = 24
    }))
    table.insert(titleRow, UI.Button({
      text = "Edit",
      onClick = function()
        editingHabit:set(habitIndex)
      end,
      backgroundColor = "#4a90e2",
      color = "#ffffff",
      fontSize = 14
    }))
  end

  table.insert(children, UI.Row({
    alignItems = "center",
    gap = 10,
    children = titleRow
  }))

  -- Month navigation
  table.insert(children, UI.Row({
    alignItems = "center",
    justifyContent = "space-between",
    children = {
      UI.Button({
        text = "<",
        onClick = function()
          navigateMonth(-1)
        end
      }),
      UI.Text({
        text = formatMonth(currentMonth.year, currentMonth.month),
        color = "#ffffff",
        fontSize = 24
      }),
      UI.Button({
        text = ">",
        onClick = function()
          navigateMonth(1)
        end
      })
    }
  }))

  -- Week day headers
  local weekDays = {}
  for _, dayName in ipairs({"M", "T", "W", "T", "F", "S", "S"}) do
    table.insert(weekDays, UI.Button({
      text = dayName,
      width = "40px",
      height = "20px",
      backgroundColor = "#2d2d2d",
      fontSize = 10,
      disabled = true
    }))
  end
  table.insert(children, UI.Row({
    gap = 5,
    children = weekDays
  }))

  -- Calendar grid (6 rows x 7 columns)
  for weekRow = 0, 5 do
    local rowChildren = {}
    for dayCol = 0, 6 do
      local dayIndex = weekRow * 7 + dayCol + 1
      local day = calendarDays[dayIndex]
      local style = getDayStyle(day)

      table.insert(rowChildren, UI.Button({
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
      }))
    end
    table.insert(children, UI.Row({
      gap = 5,
      children = rowChildren
    }))
  end

  return UI.TabPanel({
    backgroundColor = "#1a1a1a",
    padding = 30,
    children = children
  })
end

-- Helper to build tabs and panels from habits
local function buildTabsAndPanels(habitsList)
  local tabs = {}
  local panels = {}

  -- Create tab and panel for each habit
  for i, habit in ipairs(habitsList) do
    tabs[i] = UI.Tab({
      title = habit.name,
      backgroundColor = "#3d3d3d",
      activeBackgroundColor = "#4a90e2",
      textColor = "#ffffff",
      activeTextColor = "#ffffff"
    })
    panels[i] = buildHabitPanel(habit, i)
  end

  -- Add "+" button tab
  tabs[#tabs + 1] = UI.Tab({
    title = "+",
    width = "50px",
    backgroundColor = "#3d3d3d",
    onClick = addNewHabit
  })

  return tabs, panels
end

-- Main UI tree
local function buildUI()
  local currentHabits = habits:get()
  local tabs, panels = buildTabsAndPanels(currentHabits)

  return UI.Column({
    width = "800px",
    height = "600px",
    background = "#1a1a1a",
    windowTitle = "Habits",
    children = {
      UI.TabGroup({
        selectedIndex = selectedHabit:get() - 1,
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

-- Return app object
return {
  root = buildUI(),
  window = {
    width = 800,
    height = 600,
    title = "Habits"
  }
}
