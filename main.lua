-- Habits Tracker - Clean Automatic Reactivity Version
-- Platform-agnostic: uses DateTime plugin for all date/time operations

local Reactive = require("kryon.reactive")
local UI = require("kryon.dsl")
local ColorPalette = require("components.color_palette")
local DateTime = require("datetime")

-- Seed random number generator using DateTime
local now = DateTime.now()
math.randomseed(now.hour * 3600 + now.minute * 60 + now.second)

-- Load storage plugin (direct JSON files)
local Storage = require("storage")

-- Initialize storage once - app name will be used to construct ~/.local/share/habits
Storage.init("habits")

-- ============================================================================
-- Helper Functions
-- ============================================================================

local function getCurrentDate()
  return DateTime.format(DateTime.now(), "%Y-%m-%d")
end

-- ============================================================================
-- Persistence
-- ============================================================================

local function loadHabits()
  local today = getCurrentDate()

  local defaultHabits = {
    {name = "Meditation", createdAt = today, completions = {}, color = "#9b59b6"},
    {name = "Exercise", createdAt = today, completions = {}, color = "#27ae60"},
    {name = "Reading", createdAt = today, completions = {}, color = "#5c6bc0"}
  }

  -- Load from collection storage
  local habits = Storage.Collections.load("habits", defaultHabits)

  -- Ensure completions tables exist
  for i, habit in ipairs(habits) do
    if not habit.completions or type(habit.completions) ~= "table" then
      habit.completions = {}
    end
  end

  -- Ensure color property exists for migration
  for i, habit in ipairs(habits) do
    if not habit.color or habit.color == "" then
      habit.color = ColorPalette.DEFAULT_COLOR
    end
  end

  return habits
end

local function saveHabits(habits)
  -- Save collection (storage plugin handles reactive unwrapping internally)
  Storage.Collections.save("habits", habits)
end

-- ============================================================================
-- Reactive State - Clean and Simple!
-- ============================================================================
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

local state = Reactive.reactive({
  habits = habitsData,
  selectedHabit = 1,
  editingHabit = 0,
  showColorPicker = false,  -- Controls color picker modal visibility
  displayedMonth = {
    year = initialYear,
    month = initialMonth
  }
})

-- Non-reactive editing state (doesn't trigger rebuilds on every keystroke)
local editingState = {
  name = ""
}

-- ============================================================================
-- Event Handlers - Dramatically Simplified!
-- ============================================================================

local Calendar = require("components.calendar")

local function addNewHabit()
  -- Use direct index assignment to trigger reactive __newindex
  -- (table.insert bypasses the metatable and doesn't update _target)
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
    -- Remove from reactive array by shifting elements down
    for i = habitIndex, #state.habits - 1 do
      state.habits[i] = state.habits[i + 1]
    end
    state.habits[#state.habits] = nil

    -- Adjust selected habit if needed
    if state.selectedHabit > #state.habits then
      state.selectedHabit = math.max(1, #state.habits)
    elseif state.selectedHabit == habitIndex and #state.habits > 0 then
      state.selectedHabit = math.max(1, habitIndex - 1)
    end

    -- Clear editing state if deleting the habit being edited
    if state.editingHabit == habitIndex then
      state.editingHabit = 0
    end

    saveHabits(state.habits)
  end
end

local function navigateMonth(offset)
  print("[Habits] navigateMonth called with offset: " .. tostring(offset))
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

  print("[Habits] New month: " .. newYear .. "-" .. newMonth)

  if Storage.set then
    print("[Habits] Calling Storage.set for month persistence")
    Storage.set("displayedMonth", newYear .. "-" .. newMonth)
  else
    print("[Habits] Storage.set not available (desktop mode)")
  end
end

-- ============================================================================
-- UI Components
-- ============================================================================

local Tabs = require("components.tabs")

-- ============================================================================
-- Main UI - Automatically Reactive!
-- ============================================================================

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
