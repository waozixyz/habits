-- Habits Tracker - Clean Automatic Reactivity Version

local Reactive = require("kryon.reactive")
local UI = require("kryon.dsl")
local ColorPalette = require("components.color_palette")

-- Seed random number generator
math.randomseed(os.time())

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
local habitsData = loadHabits()

-- Load saved displayed month (for web persistence across refreshes)
-- Bug 4 fix: Use Runtime.getCurrentDate() for web (Fengari os.date fails)
local initialYear, initialMonth
local isWeb, js = pcall(require, "js")
if isWeb and js then
  -- Web mode: use Runtime which has JS Date helpers
  local Runtime = require("kryon.runtime_web")
  local now = Runtime.getCurrentDate()
  initialYear = now.year
  initialMonth = now.month
else
  -- Desktop mode: os.date works fine
  initialYear = tonumber(os.date("%Y"))
  initialMonth = tonumber(os.date("%m"))
end

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

-- Global function for web event handlers
_G.toggleHabitCompletion = function(habitIndex, dateStr)
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

  -- For web: persist month (reactive effects will update DOM)
  if Storage.set then
    print("[Habits] Calling Storage.set for month persistence")
    Storage.set("displayedMonth", newYear .. "-" .. newMonth)
    -- NOTE: No forceRefresh() - reactive effects handle DOM updates
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

-- ============================================================================
-- Web Reactivity Setup
-- When running in browser (Fengari), set up reactive DOM updates
-- ============================================================================

local isWeb, js = pcall(require, "js")
if isWeb and js then
  print("[Habits] Web mode detected - setting up reactive bindings")
  local document = js.global.document

  -- Set up reactive effect for calendar cell updates
  -- When habit completions change, update the corresponding DOM cells
  Reactive.effect(function()
    print("[Habits] Reactive effect running: updating calendar cells")

    -- Iterate all habits and their completions
    for i, habit in ipairs(state.habits) do
      local habitColor = habit.color or "#4a90e2"

      -- Update all cells for this habit
      if habit.completions then
        for date, completed in pairs(habit.completions) do
          -- Find the button with matching data attributes
          local selector = string.format('[data-habit="%d"][data-date="%s"]', i, date)
          local elements = document:querySelectorAll(selector)

          for j = 0, elements.length - 1 do
            local el = elements[j]
            if completed then
              el.style.backgroundColor = habitColor
              el.style.color = "#ffffff"
            else
              el.style.backgroundColor = "#3d3d3d"
              el.style.color = "#888888"
            end
          end
        end
      end
    end
  end)

  -- Set up reactive effect for month display updates
  -- Bug 4 fix: Use Runtime.formatMonthYear instead of os.date (Fengari fails)
  local Runtime = require("kryon.runtime_web")
  Reactive.effect(function()
    print("[Habits] Reactive effect running: updating month displays")

    local monthText = Runtime.formatMonthYear(state.displayedMonth.year, state.displayedMonth.month)

    -- Update all month displays (one per habit panel)
    for i = 1, #state.habits do
      local elementId = "month-display-" .. i
      local element = document:getElementById(elementId)
      if element then
        element.textContent = monthText
        print("[Habits] Updated month display: " .. elementId .. " to " .. monthText)
      end
    end
  end)

  print("[Habits] Reactive bindings initialized")
end

return app
