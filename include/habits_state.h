// habits_state.h
#ifndef HABITS_STATE_H
#define HABITS_STATE_H

#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include "config.h"
#include "rocks_clay.h"
#include "components/text_input.h"

#define MAX_CALENDAR_DAYS 1000
#define MAX_HABITS 10
#define MAX_HABIT_NAME 32


typedef struct {
    time_t date;      // Unix timestamp
    bool completed;
} HabitDay;

typedef struct {
    uint32_t row_index;
    bool is_collapsed;
} CollapsedRow;


typedef struct {
    char name[MAX_HABIT_NAME];
    uint32_t id;
    Clay_Color color;
    HabitDay calendar_days[MAX_CALENDAR_DAYS];
    size_t days_count;
} Habit;

typedef struct {
    Habit habits[MAX_HABITS];
    size_t habits_count;
    uint32_t active_habit_id;
    bool is_editing_new_habit;
    Rocks_TextInput* habit_name_input;
    bool is_calendar_expanded;
    int extra_weeks;
    bool has_done_initial_scroll;  
    int calendar_offset_weeks;
} HabitCollection;

// Public API
void SaveHabits(HabitCollection* collection);
void LoadHabits(HabitCollection* collection);
bool ToggleHabitDay(HabitCollection* collection, time_t date);
void UpdateHabitColor(HabitCollection* collection, Clay_Color color);
Habit* GetActiveHabit(HabitCollection* collection);
void AddNewHabit(HabitCollection* collection);
Habit* GetHabitById(HabitCollection* collection, uint32_t id);
void UpdateCalendarStartDate(HabitCollection* collection, time_t new_start_date);
void DeleteHabit(HabitCollection* collection, uint32_t habit_id);
bool IsHabitCompletedForDate(const Habit* habit, time_t date);

#endif