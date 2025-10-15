import ../kryon/src/kryon
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
    completions: Table[string, bool]

    
const HABITS_FILE = "~/Documents/quest/habits.json"

# Load habits from JSON file
proc loadHabits(): seq[Habit] =

    let today = $now().format("yyyy-MM-dd")

    let defaultHabits = @[
        Habit(name: "Meditation", createdAt: today, completions: initTable[string, bool]()),
        Habit(name: "Exercise",   createdAt: today, completions: initTable[string, bool]()),
        Habit(name: "Reading",    createdAt: today, completions: initTable[string, bool]())
    ]
    let filePath = expandTilde(HABITS_FILE)

    # Create directory if it doesn't exist
    let dir = parentDir(filePath)
    if not dirExists(dir):
        createDir(dir)

    # If file doesn't exist, return default habits
    if not fileExists(filePath):
        return defaultHabits

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

        return habits
    except:
        return defaultHabits

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
    except:
        echo "Error saving habits: ", getCurrentExceptionMsg()



var habits = loadHabits()
var selectedHabit = 0


# Helper function to generate calendar days for current month
proc generateCalendarDays(habit: Habit): seq[CalendarDay] =
  let now = now()
  # Use named arguments to correctly specify the timezone
  let todayStart = dateTime(now.year, now.month, now.monthday, zone = now.timezone)
  let startOfMonth = dateTime(todayStart.year, todayStart.month, 1, zone = todayStart.timezone)

  var days: seq[CalendarDay] = @[]

  # Add days from previous month to fill the first week
  let startWeekday = weekday(startOfMonth)
  let prevMonthPaddingCount = startWeekday.ord

  if prevMonthPaddingCount > 0:
    let prevMonth = startOfMonth - initDuration(days = 1)
    let prevMonthDaysCount = getDaysInMonth(prevMonth.month, prevMonth.year)
    let firstPaddingDay = prevMonthDaysCount - prevMonthPaddingCount + 1

    for i in firstPaddingDay..prevMonthDaysCount:
      days.add(CalendarDay(
        dayNumber: i,
        isPast: true,
        isToday: false,
        isCompleted: false,
        date: ""
      ))

  # Add current month days
  for day in 1..getDaysInMonth(todayStart.month, todayStart.year):
    let dayDateTime = startOfMonth + initDuration(days = day - 1)
    let dateStr = dayDateTime.format("yyyy-MM-dd")
    let isCompleted = habit.completions.getOrDefault(dateStr, false)
    days.add(CalendarDay(
      dayNumber: day,
      isPast: dayDateTime < todayStart,
      isToday: dayDateTime.year == todayStart.year and
               dayDateTime.month == todayStart.month and
               dayDateTime.monthday == todayStart.monthday,
      isCompleted: isCompleted,
      date: dateStr
    ))

  # Add days from next month to complete the grid
  let remainingDays = 42 - days.len
  if remainingDays > 0:
    for day in 1..remainingDays:
      days.add(CalendarDay(
        dayNumber: day,
        isPast: false,
        isToday: false,
        isCompleted: false,
        date: ""
      ))

  return days

# Helper to get current habit's calendar
proc getCurrentCalendarDays(): seq[CalendarDay] =
  # Register dependency on selected habit for reactive updates
  registerDependency("selectedHabit")
  registerDependency("tabSelectedIndex")

  if selectedHabit >= 0 and selectedHabit < habits.len:
    return generateCalendarDays(habits[selectedHabit])
  return @[]

var calendarDays = getCurrentCalendarDays()
    

# Add new habit handler
proc addNewHabitHandler() =
  let newHabit = Habit(
    name: "New Habit",
    createdAt: $now().format("yyyy-MM-dd"),
    completions: initTable[string, bool]()
  )
  habits.add(newHabit)
  selectedHabit = habits.len - 1

  # Save to file
  saveHabits(habits)

  # Update calendar
  calendarDays = getCurrentCalendarDays()


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
        for i in 0..<habits.len:
          Tab:
            title = habits[i].name
            backgroundColor = "#3d3d3d"
            activeBackgroundColor = "#4a90e2"
            textColor = "#ffffff"
            activeTextColor = "#ffffff"

        # Add new habit button (as a Tab)
        Tab:
          title = "+"
          width = 50
          backgroundColor = "#3d3d3d"
          onClick = addNewHabitHandler

      TabContent:
        backgroundColor = "#1a1a1a"
        Text:
          text: "hi"

        for habit in habits:     
          TabPanel:
            backgroundColor = "#1a1a1a"
            padding = 30

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
              for dayName in ["M", "T", "W", "T", "F", "S", "S"]:
                Button:
                  text = dayName
                  width = 40
                  height = 20
                  backgroundColor = "#2d2d2d"
                  fontSize = 10

            for weekStart in countup(0, 35, 7):
              Row:
                gap = 5
                for i in 0..6:                  
                  let dayIndex = weekStart + i
                  echo "Day Index: " & intToStr(dayIndex) & " Weekstart: " & intToStr(weekStart) & " i:" & intToStr(i)
                  Button:
                    width = 40
                    height = 40
                    fontSize = 12
                    text = dayIndex



