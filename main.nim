## Habits Tracker App
## Converted from .kry syntax to Nim with Tab components

import ../kryon/src/kryon
import ../kryon/src/backends/raylib_backend
import times
import strutils

# Calendar day data structure
type CalendarDay = object
  dayNumber: int
  isPast: bool
  isToday: bool
  isCompleted: bool
  date: string

# Helper function to generate calendar days for current month
proc generateCalendarDays(): seq[CalendarDay] =
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
    days.add(CalendarDay(
      dayNumber: day,
      isPast: dayDateTime < now,
      isToday: dayDateTime.monthday == currentDate.monthday,
      isCompleted: false, # This would be loaded from habit data
      date: dayDateTime.format("yyyy-MM-dd")
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
var habits = @["Meditation", "Exercise", "Reading"]
var selectedHabit = 0
var calendarDays = generateCalendarDays()

# CalendarDay component - similar to C version's calendar box
proc CalendarDayBox(day: CalendarDay): Element =
  let baseColor = if day.isPast: "#333333"
                  elif day.isToday: "#4a90e2"
                  else: "#555555"

  Button:
    text = $day.dayNumber
    width = 40
    height = 40
    backgroundColor = baseColor
    fontSize = 12
    onClick = proc() = echo "Day clicked: ", day.date

# CalendarWeek component - creates a row of 7 calendar days
proc CalendarWeek(startIndex: string): Element =
  let startIndexInt = parseInt(startIndex)
  Row:
    gap = 5
    CalendarDayBox(calendarDays[startIndexInt + 0])
    CalendarDayBox(calendarDays[startIndexInt + 1])
    CalendarDayBox(calendarDays[startIndexInt + 2])
    CalendarDayBox(calendarDays[startIndexInt + 3])
    CalendarDayBox(calendarDays[startIndexInt + 4])
    CalendarDayBox(calendarDays[startIndexInt + 5])
    CalendarDayBox(calendarDays[startIndexInt + 6])

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
      gap = 20

      Text:
        text = habit & " Tracker"
        color = "#ffffff"
        fontSize = 24

      Text:
        text = "Track your " & habit & " habit here"
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

      # Calendar days grid - create proper 6-week calendar using for loops
      for weekStart in @[0, 7, 14, 21, 28, 35]:
        CalendarWeek(weekStart)

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
