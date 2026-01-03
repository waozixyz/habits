-- Habits Tracker - Clean Automatic Reactivity Version

local Reactive = require("kryon.reactive")
local UI = require("kryon.dsl")
local ColorPalette = require("components.color_palette")

-- Load storage plugin (direct JSON files)
local Storage = require("storage")

-- Initialize storage once - app name will be used to construct ~/.local/share/habits
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
  -- Use Reactive.toRaw to get the underlying data structure
  local rawHabits = Reactive.toRaw(habits)

  -- Save collection (auto-saves to disk)
  Storage.Collections.save("habits", rawHabits)
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

-- Non-reactive editing state (doesn't trigger rebuilds on every keystroke)
local editingState = {
  name = ""
}

print("[STATE] Created reactive state")
print("[STATE] Number of habits:", #state.habits)
for i, h in ipairs(state.habits) do
  print("[STATE] Habit " .. i .. " properties:")
  for k, v in pairs(h) do
    print("[STATE]   " .. k .. " = " .. tostring(v))
  end
end

-- ============================================================================
-- Event Handlers - Dramatically Simplified!
-- ============================================================================

local Calendar = require("components.calendar")

local function addNewHabit()
  table.insert(state.habits, {
    name = "New Habit",
    createdAt = getCurrentDate(),
    completions = {},
    color = ColorPalette.DEFAULT_COLOR
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
  local newValue = not oldValue

  print(string.format("⚡ Toggling habit %d, date %s: %s -> %s", habitIndex, dateStr, tostring(oldValue), tostring(newValue)))

  -- Modify the reactive state
  completions[dateStr] = newValue

  -- Verify the write happened
  print(string.format("✓ After write: completions[%s] = %s", dateStr, tostring(completions[dateStr])))

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

local Tabs = require("components.tabs")

-- ============================================================================
-- Main UI - Automatically Reactive!
-- ============================================================================

local function buildUI()
  local selected = state.selectedHabit
  local tabs, panels = Tabs.buildTabsAndPanels(UI, state, editingState, toggleHabitCompletion, updateHabitName, navigateMonth, addNewHabit, state.habits, updateHabitColor)

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
