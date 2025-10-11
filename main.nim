## Habits Tracker App
## Converted from .kry syntax to Nim with Tab components

import ../kryon/src/kryon
import ../kryon/src/backends/raylib_backend
import times
import strutils
import json
import os
import tables

# Data structures
type
  CalendarDay = object
    dayNumber: int
    isPast: bool
    isToday: bool
    isCompleted: bool
    date: string

  Habit = object
    name: string
    createdAt: string
    completions: Table[string, bool]  # date -> completed

# File path for storing habits data
const HABITS_FILE = "~/Documents/quest/habits.json"

# Helper function to expand ~ in file paths
proc expandTilde(path: string): string =
  if path.startsWith("~/"):
    return getHomeDir() / path[2..^1]
  return path

# Load habits from JSON file
proc loadHabits(): seq[Habit] =
  let filePath = expandTilde(HABITS_FILE)

  # Create directory if it doesn't exist
  let dir = parentDir(filePath)
  if not dirExists(dir):
    createDir(dir)

  # If file doesn't exist, return default habits
  if not fileExists(filePath):
    echo "Habits file not found, creating default habits"
    return @[
      Habit(name: "Meditation", createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]()),
      Habit(name: "Exercise", createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]()),
      Habit(name: "Reading", createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]())
    ]

  # Load and parse JSON
  try:
    let jsonContent = readFile(filePath)
    let jsonNode = parseJson(jsonContent)
    var habits: seq[Habit] = @[]

    for habitNode in jsonNode["habits"]:
      var habit = Habit(
        name: habitNode["name"].getStr(),
        createdAt: habitNode["createdAt"].getStr(),
        completions: initTable[string, bool]()
      )

      # Load completions
      if habitNode.hasKey("completions"):
        for date, completed in habitNode["completions"].pairs():
          habit.completions[date] = completed.getBool()

      habits.add(habit)

    echo "Loaded ", habits.len, " habits from file"
    return habits
  except:
    echo "Error loading habits: ", getCurrentExceptionMsg()
    echo "Returning default habits"
    return @[
      Habit(name: "Meditation", createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]()),
      Habit(name: "Exercise", createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]()),
      Habit(name: "Reading", createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]())
    ]

# Save habits to JSON file
proc saveHabits(habits: seq[Habit]) =
  let filePath = expandTilde(HABITS_FILE)

  # Create directory if it doesn't exist
  let dir = parentDir(filePath)
  if not dirExists(dir):
    createDir(dir)

  # Build JSON structure
  var habitsArray = newJArray()
  for habit in habits:
    var habitObj = %* {
      "name": habit.name,
      "createdAt": habit.createdAt
    }

    # Add completions
    var completionsObj = newJObject()
    for date, completed in habit.completions.pairs():
      completionsObj[date] = %completed
    habitObj["completions"] = completionsObj

    habitsArray.add(habitObj)

  let jsonNode = %* {
    "habits": habitsArray
  }

  # Write to file
  try:
    writeFile(filePath, jsonNode.pretty())
    echo "Saved ", habits.len, " habits to file"
  except:
    echo "Error saving habits: ", getCurrentExceptionMsg()

# Helper function to generate calendar days for current month
proc generateCalendarDays(habit: Habit): seq[CalendarDay] =
  let now = now()
  let currentDate = now
  let startOfMonth = currentDate - initDuration(days = currentDate.monthday - 1)

  var days: seq[CalendarDay] = @[]

  # Add days from previous month to fill first week
  let startWeekday = weekday(startOfMonth)
  let prevMonthDays = startWeekday.ord - 1
  if prevMonthDays > 0:
    let prevMonth = currentDate - initDuration(days = currentDate.monthday)
    let prevMonthDaysCount = getDaysInMonth(prevMonth.month, prevMonth.year)
    for i in countdown(prevMonthDaysCount - prevMonthDays + 1, prevMonthDaysCount):
      days.add(CalendarDay(
        dayNumber: i,
        isPast: true,
        isToday: false,
        isCompleted: false,
        date: ""
      ))

  # Add current month days
  for day in 1..getDaysInMonth(currentDate.month, currentDate.year):
    let dayDateTime = startOfMonth + initDuration(days = day - 1)
    let dateStr = dayDateTime.format("yyyy-MM-dd")
    let isCompleted = habit.completions.getOrDefault(dateStr, false)
    days.add(CalendarDay(
      dayNumber: day,
      isPast: dayDateTime < now,
      isToday: dayDateTime.monthday == currentDate.monthday,
      isCompleted: isCompleted,
      date: dateStr
    ))

  # Add days from next month to complete the grid
  let totalDays = days.len
  let remainingDays = 42 - totalDays # 6 weeks * 7 days
  for day in 1..remainingDays:
    days.add(CalendarDay(
      dayNumber: day,
      isPast: false,
      isToday: false,
      isCompleted: false,
      date: ""
    ))

  return days

# Application state
var habits = loadHabits()
var selectedHabit = 0

# Helper to get current habit's calendar
proc getCurrentCalendarDays(): seq[CalendarDay] =
  if selectedHabit >= 0 and selectedHabit < habits.len:
    return generateCalendarDays(habits[selectedHabit])
  return @[]

var calendarDays = getCurrentCalendarDays()


# Create reactive event handler for completion toggles
proc createToggleCompletionHandler(date: string): proc() =
  return proc() =
    if selectedHabit >= 0 and selectedHabit < habits.len:
      # Toggle the completion status
      let currentStatus = habits[selectedHabit].completions.getOrDefault(date, false)
      habits[selectedHabit].completions[date] = not currentStatus

      # Save to file
      saveHabits(habits)

      # Update calendar display
      calendarDays = getCurrentCalendarDays()

      echo "Toggled completion for ", date, " to ", not currentStatus

# CalendarDay component - similar to C version's calendar box
proc CalendarDayBox(day: CalendarDay): Element =
  # Color based on completion status and day type (but subtle today)
  let baseColor = if day.isCompleted: "#22c55e"  # Green for completed
                  elif day.isPast: "#333333"     # Dark gray for past days
                  else: "#555555"                # Gray for future/incomplete

  # Only allow clicking on current month days (those with a date)
  let clickHandler = if day.date != "":
    createToggleCompletionHandler(day.date)
  else:
    proc() = echo "Invalid day"

  Button:
    text = $day.dayNumber  # No unicode symbols
    width = 40
    height = 40
    backgroundColor = baseColor
    fontSize = 12
    onClick = clickHandler

# CalendarWeek component - creates a row of 7 calendar days
proc CalendarWeek(calendar: seq[CalendarDay], startIndex: int): Element =
  Row:
    gap = 5
    CalendarDayBox(calendar[startIndex + 0])
    CalendarDayBox(calendar[startIndex + 1])
    CalendarDayBox(calendar[startIndex + 2])
    CalendarDayBox(calendar[startIndex + 3])
    CalendarDayBox(calendar[startIndex + 4])
    CalendarDayBox(calendar[startIndex + 5])
    CalendarDayBox(calendar[startIndex + 6])

# Helper to get habit names for for loops (reactive)
var habitNames: seq[string] = @[]

proc updateHabitNames() =
  habitNames = @[]
  for habit in habits:
    habitNames.add(habit.name)

# Initialize habit names
updateHabitNames()

# Add new habit handler
proc addNewHabitHandler() =
  echo "Adding new habit"
  let newHabit = Habit(
    name: "New Habit",
    createdAt: $now().format("yyyy-MM-dd"),
    completions: initTable[string, bool]()
  )
  habits.add(newHabit)
  selectedHabit = habits.len - 1

  # Update habit names list for UI
  updateHabitNames()

  # Save to file
  saveHabits(habits)

  # Update calendar
  calendarDays = getCurrentCalendarDays()

  echo "Selected tab: ", selectedHabit

# Create reactive event handler that invalidates habits and selectedHabit
let addNewHabit = createReactiveEventHandler(addNewHabitHandler, @["habits", "selectedHabit"])

# Helper to find habit by name
proc findHabitByName(name: string): Habit =
  for habit in habits:
    if habit.name == name:
      return habit
  # Return a default habit if not found
  return Habit(name: name, createdAt: $now().format("yyyy-MM-dd"), completions: initTable[string, bool]())

# HabitPanel component - displays content for each habit tab
proc HabitPanel(habitName: string): Element =
  let habit = findHabitByName(habitName)
  TabPanel:
    backgroundColor = "#1a1a1a"
    padding = 30

    Column:
      gap = 20

      Text:
        text = habit.name & " Tracker"
        color = "#ffffff"
        fontSize = 24

      Text:
        text = "Track your " & habit.name & " habit here"
        color = "#aaaaaa"
        fontSize = 14

      # Calendar grid section
      Text:
        text = "Calendar"
        color = "#ffffff"
        fontSize = 18

      # Week day headers
      Row:
        gap = 5
        Button:
          text = "S"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: S"
        Button:
          text = "M"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: M"
        Button:
          text = "T"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: T1"
        Button:
          text = "W"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: W"
        Button:
          text = "T"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: T2"
        Button:
          text = "F"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: F"
        Button:
          text = "S"
          width = 40
          height = 20
          backgroundColor = "#2d2d2d"
          fontSize = 10
          onClick = proc() = echo "Day header clicked: S"

      # Calendar days grid - use reactive calendarDays
      CalendarWeek(calendarDays, 0)
      CalendarWeek(calendarDays, 7)
      CalendarWeek(calendarDays, 14)
      CalendarWeek(calendarDays, 21)
      CalendarWeek(calendarDays, 28)
      CalendarWeek(calendarDays, 35)

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
        for habitName in habitNames:
          Tab:
            title = habitName
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
        for habitName in habitNames:
          HabitPanel(habitName)

# Run the application
when isMainModule:
  var backend = newRaylibBackendFromApp(app)
  backend.run(app)
