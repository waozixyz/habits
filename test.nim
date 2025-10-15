import ../kryon/src/kryon
import times
import tables
import strutils
import json
import os

# Data structures
type
  CalendarDay = object
    dayNumber: int
    date: string 
    isCurrentMonth: bool
    isToday: bool
    isCompleted: bool
  Habit = object
    name: string
    createdAt: string
    completions: Table[string, bool]

var displayedMonth: DateTime = now()


var habits: seq[Habit] = @[
  Habit(
    name: "Read for 15 minutes",
    createdAt: "2023-10-01",
    completions: {
      "2023-10-25": true,
      "2023-10-26": true,
      "2023-10-27": false
    }.toTable # .toTable converts the literal to a Table
  ),
  Habit(
    name: "Morning workout",
    createdAt: "2023-09-15",
    completions: {
      "2023-10-26": true,
      "2023-10-27": true
    }.toTable
  ),
  Habit(
    name: "Drink 8 glasses of water",
    createdAt: "2023-10-20",
    # This habit has no completions recorded yet, so we create an empty table
    completions: initTable[string, bool]()
  )
]
    
var selectedHabit = 0

# This is our powerful, flexible, and efficient calendar data generator
proc generateCalendarData(habit: Habit, monthToDisplay: DateTime): seq[CalendarDay] =
  var result: seq[CalendarDay] = @[]
  let today = now()
  
  let startOfMonth = dateTime(monthToDisplay.year, monthToDisplay.month, 1)
  let startOffset = startOfMonth.weekday.ord
  let daysInMonth = getDaysInMonth(monthToDisplay.month, monthToDisplay.year)

  let prevMonth = startOfMonth - 1.days
  let daysInPrevMonth = getDaysInMonth(prevMonth.month, prevMonth.year)
  for i in 0 ..< startOffset:
    let dayNum = daysInPrevMonth - startOffset + 1 + i
    result.add(CalendarDay(dayNumber: dayNum, isCurrentMonth: false))

  for d in 1..daysInMonth:
    let currentDayDt = startOfMonth + (d - 1).days
    let dateStr = currentDayDt.format("yyyy-MM-dd")
    result.add(CalendarDay(
      dayNumber: d,
      date: dateStr,
      isCurrentMonth: true,
      # Check if this day is today (comparing year, month, and day)
      isToday: monthToDisplay.year == today.year and
               monthToDisplay.month == today.month and
               d == today.monthday,
      isCompleted: habit.completions.getOrDefault(dateStr, false)
    ))

  # 4. Add next month's padding to fill the 42 cells
  let nextMonthPaddingCount = 42 - result.len
  for d in 1..nextMonthPaddingCount:
    result.add(CalendarDay(dayNumber: d, isCurrentMonth: false))
  
  return result

proc addNewHabitHandler() =
  let newHabit = Habit(
    name: "New Habit",
    createdAt: $now().format("yyyy-MM-dd"),
    completions: initTable[string, bool]()
  )
  habits.add(newHabit)
  selectedHabit = habits.len - 1


# Main application
let app = kryonApp:
  Header:
      width = 800
      height = 600
      title = "Habits"

  Body:
    background = "#1a1a1a"
    echo "hi"

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

        for habit in habits:     
          TabPanel:
            backgroundColor = "#1a1a1a"
            padding = 30

            Text:
              text = habit.name & " Tracker"
              color = "#ffffff"
              fontSize = 24



            # Header with month name and navigation
            Row:
              alignItems = "center"
              justifyContent = "space-between"

              Button:
                text = "<"
                onClick = proc() =
                  displayedMonth = displayedMonth - 1.months
              
              Text:
                text = displayedMonth.format("MMMM yyyy")
                color = "#ffffff"
                fontSize = 24

              Button:
                text = ">"
                onClick = proc() =
                  displayedMonth = displayedMonth + 1.months

            let calendarDays = generateCalendarData(habit, displayedMonth)

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
                  let day = calendarDays[dayIndex]

                  Button:
                    width = 40
                    height = 40
                    fontSize = 12
                    text = if day.isCurrentMonth: $day.dayNumber else: ""
                    