## Habits Tracker App
## Converted from .kry syntax to Nim with Tab components

import ../kryon/src/kryon
import ../kryon/src/backends/raylib_backend

# Application state
var habits = @["Meditation", "Exercise", "Reading"]
var selectedHabit = 0

# Add new habit handler
proc addNewHabitHandler() =
  echo "Adding new habit"
  habits.add("New Habit")
  selectedHabit = habits.len - 1
  echo "Selected tab: ", selectedHabit

# Create reactive event handler that invalidates habits and selectedHabit
let addNewHabit = createReactiveEventHandler(addNewHabitHandler, @["habits", "selectedHabit"])

# HabitPanel component - displays content for each habit tab
proc HabitPanel(habit: string): Element =
  TabPanel:
    backgroundColor = "#1a1a1a"
    padding = 30

    Column:
      gap = 10

      Text:
        text = habit & " Tracker"
        color = "#ffffff"
        fontSize = 24

      Text:
        text = "Track your " & habit & " habit here"
        color = "#aaaaaa"
        fontSize = 14

# Main application
let app = kryonApp:
  Header:
    width = 800
    height = 600
    title = "Habits"

  Body:
    background = "#1a1a1a"

    TabGroup:
      selectedIndex = selectedHabit
      backgroundColor = "#1a1a1a"
      width = 800
      height = 600

      TabBar:
        backgroundColor = "#2d2d2d"

        # Tabs for each habit
        for habit in habits:
          Tab:
            title = habit
            backgroundColor = "#3d3d3d"
            activeBackgroundColor = "#4a90e2"
            textColor = "#ffffff"
            activeTextColor = "#ffffff"

        # Add new habit button (as a Tab)
        Tab:
          title = "+"
          width = 50
          backgroundColor = "#3d3d3d"
          onClick = addNewHabit

      TabContent:
        backgroundColor = "#1a1a1a"

        # Tab panels for each habit
        for habit in habits:
          HabitPanel(habit)

# Run the application
when isMainModule:
  var backend = newRaylibBackendFromApp(app)
  backend.run(app)
