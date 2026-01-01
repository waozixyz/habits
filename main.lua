-- Habits Tracker - Clean Automatic Reactivity Version

local Reactive = require("kryon.reactive")
local UI = require("kryon.dsl")

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

local Calendar = require("component_calendar")

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
  if not dateStr or dateStr == "" or Calendar.isDateInFuture(dateStr) then
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
-- UI Components
-- ============================================================================

local Tabs = require("component_tabs")

-- ============================================================================
-- Main UI - Automatically Reactive!
-- ============================================================================

local function buildUI()
  local selected = state.selectedHabit
  local tabs, panels = Tabs.buildTabsAndPanels(UI, state, toggleHabitCompletion, updateHabitName, navigateMonth, addNewHabit, state.habits)

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
