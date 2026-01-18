-- Habits Tracker

local UI = require("kryon.dsl")
local ColorPalette = require("components.color_palette")
local DateTime = require("datetime")

-- Seed random number generator using DateTime
local now = DateTime.now()
math.randomseed(now.hour * 3600 + now.minute * 60 + now.second)

local Storage = require("kryon.plugins.storage")
Storage.init("habits")

local function getCurrentDate()
  return DateTime.format(DateTime.now(), "%Y-%m-%d")
end

-- ============================================================================
-- Persistence
-- ============================================================================
local function loadHabits()
  local habits = Storage.Collections.load("habits", {})
  local today = getCurrentDate()

  -- Single pass for migration and defaults
  for _, habit in ipairs(habits) do
    habit.completions = type(habit.completions) == "table" and habit.completions or {}
    habit.color = (habit.color and habit.color ~= "") and habit.color or ColorPalette.DEFAULT_COLOR
    habit.createdAt = habit.createdAt or today
  end

  -- Fallback if storage is empty
  if #habits == 0 then
    return {
      {name = "Meditation", createdAt = today, completions = {}, color = "#9b59b6"},
      {name = "Exercise", createdAt = today, completions = {}, color = "#27ae60"}
    }
  end

  return habits
end

local function saveHabits(habits)
  Storage.Collections.save("habits", habits)
end

local habitsData = loadHabits()

-- Get current year/month from DateTime plugin (platform-independent)
local currentDateTime = DateTime.now()
local initialYear = currentDateTime.year
local initialMonth = currentDateTime.month

if Storage.get then  -- Web storage has get/set methods
  local savedMonth = Storage.get("displayedMonth")
  if savedMonth and type(savedMonth) == "string" then
    local year, month = string.match(savedMonth, "^(%d+)%-(%d+)$")
    if year and month then
      local y, m = tonumber(year), tonumber(month)
      if y and y > 2000 and m and m >= 1 and m <= 12 then
        initialYear = y
        initialMonth = m
      end
    end
  end
end

local state = {
  habits = habitsData,
  selectedHabit = 1,
  editingHabit = 0,
  showColorPicker = false,  -- Controls color picker modal visibility
  displayedMonth = {
    year = initialYear,
    month = initialMonth
  }
}

-- Non-reactive editing state (doesn't trigger rebuilds on every keystroke)
local editingState = {
  name = ""
}

-- ============================================================================
-- Event Handlers - Dramatically Simplified!
-- ============================================================================

local Calendar = require("components.calendar")

local function addNewHabit()
  local newIndex = #state.habits + 1
  state.habits[newIndex] = {
    name = "New Habit",
    createdAt = getCurrentDate(),
    completions = {},
    color = ColorPalette.getRandomColor()
  }
  state.selectedHabit = newIndex
  saveHabits(state.habits)
end

-- Toggle habit completion for a date
local function toggleHabitCompletion(habitIndex, dateStr)
  if not dateStr or dateStr == "" or Calendar.isDateInFuture(dateStr) then
    return
  end

  local completions = state.habits[habitIndex].completions
  local oldValue = completions[dateStr] or false
  local newValue = not oldValue

  -- Modify the reactive state
  completions[dateStr] = newValue

  -- Save to disk
  saveHabits(state.habits)
end

local function updateHabitName(habitIndex, newName)
  if state.habits[habitIndex] then
    state.habits[habitIndex].name = newName
    saveHabits(state.habits)
  end
end

local function updateHabitColor(habitIndex, newColor)
  if state.habits[habitIndex] then
    state.habits[habitIndex].color = newColor
    saveHabits(state.habits)
  end
end

local function deleteHabit(habitIndex)
  if state.habits[habitIndex] then
    -- 1. Use Lua's built-in table removal (automatically shifts elements)
    table.remove(state.habits, habitIndex)

    -- 2. Clamp the selection index so it doesn't point to a non-existent index
    -- If we deleted the last item, move selection back by one.
    state.selectedHabit = math.max(1, math.min(state.selectedHabit, #state.habits))

    -- 3. Reset editing state if necessary
    if state.editingHabit == habitIndex then
      state.editingHabit = 0
    end

    saveHabits(state.habits)
  end
end

local function navigateMonth(offset)
  -- Convert to a total number of months, apply offset, and convert back
  local totalMonths = state.displayedMonth.year * 12 + (state.displayedMonth.month - 1) + offset
  
  state.displayedMonth.year = math.floor(totalMonths / 12)
  state.displayedMonth.month = (totalMonths % 12) + 1

  if Storage.set then
    Storage.set("displayedMonth", state.displayedMonth.year .. "-" .. state.displayedMonth.month)
  end
end


local Tabs = require("components.tabs")
local function buildUI()
  local selected = state.selectedHabit
  local tabs, panels = Tabs.buildTabsAndPanels(UI, state, editingState, toggleHabitCompletion, updateHabitName, navigateMonth, addNewHabit, state.habits, updateHabitColor, deleteHabit)

  return UI.Column({
    width = "800px",
    height = "750px",
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
    height = 750,
    title = "Habits"
  }
})

return app
