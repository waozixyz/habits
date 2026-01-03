-- Tab bar and panels builder
local HabitPanel = require("components.habit_panel")

local function buildTabsAndPanels(UI, state, editingState, toggleHabitCompletion, updateHabitName, navigateMonth, addNewHabit, habitsList, updateHabitColor)
  -- Map habits to tabs
  local tabs = UI.mapArray(habitsList, function(habit, i)
    local habitColor = habit.color or "#4a90e2"
    return UI.Tab {
      title = habit.name,
      backgroundColor = "#3d3d3d",
      activeBackgroundColor = habitColor,
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

  -- Map habits to panels using manual loop
  local panels = {}
  for i, habit in ipairs(habitsList) do
    table.insert(panels, HabitPanel.buildHabitPanel(UI, state, editingState, toggleHabitCompletion, updateHabitName, navigateMonth, habit, i, updateHabitColor))
  end

  return tabs, panels
end

return {
  buildTabsAndPanels = buildTabsAndPanels
}
