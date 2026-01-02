-- Calendar data generation and styling utilities

local function getCurrentDate()
  return os.date("%Y-%m-%d")
end

local function getDaysInMonth(year, month)
  local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
    return 29
  end
  return days[month]
end

local function getWeekday(year, month, day)
  local t = os.time({year=year, month=month, day=day})
  return tonumber(os.date("%w", t))
end

local function makeDate(year, month, day)
  return os.date("%Y-%m-%d", os.time({year=year, month=month, day=day}))
end

local function isDateInFuture(dateStr)
  if not dateStr or dateStr == "" then return false end
  local year, month, day = dateStr:match("(%d+)-(%d+)-(%d+)")
  if not year then return false end

  local targetTime = os.time({year=tonumber(year), month=tonumber(month), day=tonumber(day)})
  local today = os.time({year=os.date("%Y"), month=os.date("%m"), day=os.date("%d")})
  return targetTime > today
end

-- Generate calendar data for a given habit and month
local function generateCalendarData(habit, year, month)
  local today = getCurrentDate()
  local todayYear, todayMonth, todayDay = today:match("(%d+)-(%d+)-(%d+)")
  todayYear, todayMonth, todayDay = tonumber(todayYear), tonumber(todayMonth), tonumber(todayDay)

  local daysInMonth = getDaysInMonth(year, month)
  local firstWeekday = getWeekday(year, month, 1)
  local startOffset = (firstWeekday + 6) % 7

  local days = {}

  -- Previous month padding
  local prevMonth = month - 1
  local prevYear = year
  if prevMonth == 0 then
    prevMonth = 12
    prevYear = prevYear - 1
  end
  local daysInPrevMonth = getDaysInMonth(prevYear, prevMonth)

  for i = 0, startOffset - 1 do
    local dayNum = daysInPrevMonth - startOffset + 1 + i
    table.insert(days, {
      dayNumber = dayNum,
      date = "",
      isCurrentMonth = false,
      isToday = false,
      isCompleted = false
    })
  end

  -- Current month days
  for d = 1, daysInMonth do
    local dateStr = makeDate(year, month, d)
    local isCompleted = habit.completions[dateStr] or false
    local isToday = (year == todayYear and month == todayMonth and d == todayDay)

    table.insert(days, {
      dayNumber = d,
      date = dateStr,
      isCurrentMonth = true,
      isToday = isToday,
      isCompleted = isCompleted
    })
  end

  -- Next month padding
  local nextMonthDays = 42 - #days
  for d = 1, nextMonthDays do
    table.insert(days, {
      dayNumber = d,
      date = "",
      isCurrentMonth = false,
      isToday = false,
      isCompleted = false
    })
  end

  return days
end

-- Get styling for a calendar day cell
local function getDayStyle(day)
  local style = {
    backgroundColor = "#3d3d3d",
    color = "#ffffff"
  }

  if day.isCompleted then
    style.backgroundColor = "#4a90e2"
  elseif day.isToday then
    style.borderColor = "#4a90e2"
  elseif not day.isCurrentMonth then
    style.backgroundColor = "#2d2d2d"
  end

  return style
end

return {
  generateCalendarData = generateCalendarData,
  getDayStyle = getDayStyle,
  isDateInFuture = isDateInFuture
}
