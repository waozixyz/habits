# Plan: Simplify calendar.kry by Improving DateTime Plugin

## Goal
Reduce calendar.kry complexity by improving the DateTime plugin and removing unnecessary wrapper functions.

## Current Problems

### 1. Useless Wrapper Functions in calendar.kry
These functions just pass through to DateTime with no added value:
- `getDaysInMonth(year, month)` → `DateTime.daysInMonth(year, month)`
- `getWeekday(year, month, day)` → `DateTime.weekday(year, month, day)`
- `makeDate(year, month, day)` → `DateTime.makeDate(year, month, day)`
- `getCurrentDate()` → `DateTime.format(DateTime.now(), "%Y-%m-%d")`

### 2. Missing Functions in calendar.kry
habit_panel.kry calls functions that don't exist:
- `getMonthLabel()` - needs to be created
- `getWeekHeaders()` - needs to be created
- `navigateMonth(delta)` - needs to be created
- `isCurrentMonth()` - needs to be created
- `getCalendarRows()` - named `generateCalendarRows` in calendar.kry
- `handleDayClick(day)` - needs to be created
- `getHabitColor()` - needs to be created
- `handleEditClick()` - needs to be created

### 3. Missing DateTime Plugin Features
- `DateTime.today()` - shortcut for getting YYYY-MM-DD string of today
- `DateTime.isFuture(dateStr)` - accepting date string instead of (year, month, day) tuple

### 4. Bugs Found
- main.kry line 52: `displayedMonh` typo (should be `displayedMonth`)
- main.kry line 53-54: `initialYear` and `initialMonth` undefined

---

## Solution: Two-Phase Approach

### Phase 1: Improve DateTime Plugin

Add to `/home/wao/Projects/KryonLabs/kryon-plugins/datetime/bindings/lua/datetime.lua`:

```lua
--- Get today's date as YYYY-MM-DD string
-- @return string Today's date in YYYY-MM-DD format
function DateTime.today()
    local cdt = ffi.new("KryonDateTime")
    local result = lib.kryon_datetime_now(cdt)
    if result ~= 0 then
        error("DateTime.today failed")
    end
    return ffi.string(lib.kryon_datetime_make_date(cdt.year, cdt.month, cdt.day, DateTime._buffer, DateTime._buffer_size))
end

--- Check if a date string is in the future
-- @param dateStr string Date in YYYY-MM-DD format
-- @return boolean True if date is in the future
function DateTime.isFutureDate(dateStr)
    if not dateStr or dateStr == "" then
        return false
    end

    -- Parse the date string
    local year, month, day = dateStr:match("^(%d+)-(%d+)-(%d+)$")
    if not year then
        return false
    end

    return lib.kryon_datetime_is_future(tonumber(year), tonumber(month), tonumber(day))
end

--- Get month name from month number
-- @param month number Month (1-12)
-- @param boolean abbrev If true, return abbreviated name
-- @return string Month name
function DateTime.monthName(month, abbrev)
    local names = {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    }
    local abbrevs = {
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    }
    if abbrev then
        return abbrevs[month] or ""
    else
        return names[month] or ""
    end
end

--- Get weekday name from weekday number
-- @param weekday number Weekday (0=Sunday, 6=Saturday)
-- @param boolean abbrev If true, return abbreviated name
-- @return string Weekday name
function DateTime.weekdayName(weekday, abbrev)
    local names = {
        "Sunday", "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    }
    local abbrevs = {
        "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
    }
    if abbrev then
        return abbrevs[weekday + 1] or ""
    else
        return names[weekday + 1] or ""
    end
end
```

### Phase 2: Simplify calendar.kry

Remove wrapper functions and add missing helpers:

```kry
// Calendar Module - Simplified
// Uses DateTime plugin directly for most operations

import DateTime from "datetime"

func isDateInFuture(dateStr) {
  return DateTime.isFutureDate(dateStr)
}

// Get calendar data for habit display
// Returns 6 rows of 7 days each with styling applied
func getCalendarRows(habit, year, month, themeColor) {
  var today = DateTime.today()
  var todayParts = today.split("-")
  var todayYear = todayParts[0].toNumber()
  var todayMonth = todayParts[1].toNumber()
  var todayDay = todayParts[2].toNumber()

  var daysInMonth = DateTime.daysInMonth(year, month)
  var firstWeekday = DateTime.weekday(year, month, 1)
  var startOffset = (firstWeekday + 6) % 7

  var days = []

  // Previous month padding
  var prevMonth = month - 1
  var prevYear = year
  if prevMonth == 0 {
    prevMonth = 12
    prevYear = prevYear - 1
  }
  var daysInPrevMonth = DateTime.daysInMonth(prevYear, prevMonth)

  for i in 0..startOffset {
    var dayNum = daysInPrevMonth - startOffset + 1 + i
    days.push({
      dayNumber = dayNum,
      date = "",
      isCurrentMonth = false,
      isToday = false,
      isCompleted = false,
      backgroundColor = "#2d2d2d",
      color = "#666666",
      disabled = true
    })
  }

  // Current month days
  for d in 1..daysInMonth {
    var dateStr = DateTime.makeDate(year, month, d)
    var isCompleted = habit.completions[dateStr] or false
    var isToday = (year == todayYear and month == todayMonth and d == todayDay)
    var isFuture = DateTime.isFutureDate(dateStr)

    var backgroundColor = "#3d3d3d"
    var borderColor = null
    var color = "#ffffff"
    var disabled = false

    if isCompleted {
      backgroundColor = themeColor or "#4a90e2"
    } else if isToday {
      borderColor = themeColor or "#4a90e2"
    } else if isFuture {
      disabled = true
      color = "#666666"
    }

    days.push({
      dayNumber = d,
      date = dateStr,
      isCurrentMonth = true,
      isToday = isToday,
      isCompleted = isCompleted,
      backgroundColor = backgroundColor,
      borderColor = borderColor,
      color = color,
      disabled = disabled
    })
  }

  // Next month padding
  var nextMonthDays = 42 - days.length
  for d in 1..nextMonthDays {
    days.push({
      dayNumber = d,
      date = "",
      isCurrentMonth = false,
      isToday = false,
      isCompleted = false,
      backgroundColor = "#2d2d2d",
      color = "#666666",
      disabled = true
    })
  }

  // Convert to rows
  var rows = []
  for weekRow in 0..5 {
    var rowDays = []
    for dayCol in 0..6 {
      var dayIndex = weekRow * 7 + dayCol
      rowDays.push(days[dayIndex])
    }
    rows.push({
      days = rowDays
    })
  }

  return rows
}

func getWeekHeaders() {
  return ["S", "M", "T", "W", "T", "F", "S"]
}

func getMonthLabel(year, month) {
  return DateTime.monthName(month) + " " + year
}

return {
  getCalendarRows,
  getWeekHeaders,
  getMonthLabel,
  isDateInFuture
}
```

---

## habit_panel.kry Changes Needed

Need to add state and handler functions that are missing:

```kry
// Add these after imports
var displayedMonth = {
  year = DateTime.now().year,
  month = DateTime.now().month
}

func navigateMonth(delta) {
  displayedMonth.month = displayedMonth.month + delta
  if displayedMonth.month > 12 {
    displayedMonth.month = 1
    displayedMonth.year = displayedMonth.year + 1
  } else if displayedMonth.month < 1 {
    displayedMonth.month = 12
    displayedMonth.year = displayedMonth.year - 1
  }
}

func isCurrentMonth() {
  var now = DateTime.now()
  return displayedMonth.year == now.year and displayedMonth.month == now.month
}

func getMonthLabel() {
  return Calendar.getMonthLabel(displayedMonth.year, displayedMonth.month)
}

func getHabitColor() {
  return habit.color or DEFAULT_COLOR
}

func handleDayClick(day) {
  if not day.disabled and day.isCurrentMonth {
    if habit.completions[day.date] {
      delete habit.completions[day.date]
    } else {
      habit.completions[day.date] = true
    }
    Storage.save("habits", habits)
  }
}

func handleEditClick() {
  editingHabit = not editingHabit
}
```

---

## main.kry Changes Needed

Fix typos and initialize variables:

```kry
// Fix line 52-55
var displayedMonth = {
  year = DateTime.now().year,
  month = DateTime.now().month
}

// Fix line 14 - use new DateTime.today()
func loadHabits() {
  var habits = Storage.load("habits", {})
  var today = DateTime.today()
  // ... rest of function
}
```

---

## Summary

### Files Modified
1. `/home/wao/Projects/KryonLabs/kryon-plugins/datetime/bindings/lua/datetime.lua`
   - Add `today()`
   - Add `isFutureDate(dateStr)`
   - Add `monthName(month, abbrev)`
   - Add `weekdayName(weekday, abbrev)`

2. `components/calendar.kry`
   - Remove: `getDaysInMonth`, `getWeekday`, `makeDate`, `getCurrentDate`, `generateCalendarData`, `getDayStyle`
   - Keep: `getCalendarRows` (renamed from generateCalendarRows), `getWeekHeaders`, `getMonthLabel`, `isDateInFuture`
   - Direct DateTime calls instead of wrappers
   - Inline styling into day objects

3. `components/habit_panel.kry`
   - Add missing state and handler functions
   - Update to use simplified calendar API

4. `main.kry`
   - Fix `displayedMonh` typo → `displayedMonth`
   - Initialize `initialYear` and `initialMonth` properly
   - Use `DateTime.today()` instead of `DateTime.getCurrentDate()`

### Lines Saved
- calendar.kry: ~40 lines removed
- DateTime plugin: +30 lines (reusable across all projects)
- habit_panel.kry: ~40 lines added (necessary state management)

### Benefits
1. Cleaner API - direct DateTime usage
2. Reusable DateTime enhancements for other projects
3. Better separation of concerns (styling in data layer)
4. All missing functions implemented
