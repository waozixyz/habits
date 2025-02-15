#include "habits_state.h"
#include "rocks.h"
#include "quest_theme.h"

#ifndef __EMSCRIPTEN__
static float lastCalendarToggleTime = 0;
const float CALENDAR_TOGGLE_DEBOUNCE_MS = 0.25f; // 250ms converted to seconds
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>

EM_JS(void, JS_SaveHabits, (const HabitCollection* collection), {});
EM_JS(void, JS_LoadHabits, (HabitCollection* collection), {});
EM_JS(void, deleteHabitFunction, (HabitCollection* collection, uint32_t habit_id), {});
EM_JS(void, addNewHabitFunction, (HabitCollection* collection), {});

#else
#include "storage_utils.h"
#include "cJSON.h"
#include <stdlib.h>
#include <time.h>

static cJSON* HabitToJSON(const Habit* habit, const HabitCollection* collection) {
   cJSON* habitObj = cJSON_CreateObject();
   cJSON_AddNumberToObject(habitObj, "id", habit->id);
   cJSON_AddStringToObject(habitObj, "name", habit->name);
   
   cJSON* color = cJSON_CreateObject();
   cJSON_AddNumberToObject(color, "r", habit->color.r);
   cJSON_AddNumberToObject(color, "g", habit->color.g);
   cJSON_AddNumberToObject(color, "b", habit->color.b);
   cJSON_AddNumberToObject(color, "a", habit->color.a);
   cJSON_AddItemToObject(habitObj, "color", color);

   cJSON_AddNumberToObject(habitObj, "start_date", (double)habit->start_date);  

   cJSON* days = cJSON_CreateArray();
   for (size_t i = 0; i < habit->days_count; i++) {
       cJSON* day = cJSON_CreateObject();
       cJSON_AddNumberToObject(day, "date", habit->calendar_days[i].date);
       cJSON_AddNumberToObject(day, "day_index", habit->calendar_days[i].day_index);
       cJSON_AddBoolToObject(day, "completed", habit->calendar_days[i].completed);
       cJSON_AddItemToArray(days, day);
   }
   cJSON_AddItemToObject(habitObj, "calendar_days", days);

    cJSON* collapsed = cJSON_CreateArray();
    for (size_t i = 0; i < collection->collapsed_rows_count; i++) {
        cJSON* row = cJSON_CreateObject();
        cJSON_AddNumberToObject(row, "index", collection->collapsed_rows[i].row_index);
        cJSON_AddItemToArray(collapsed, row);
    }
    cJSON_AddItemToObject(habitObj, "collapsed_rows", collapsed);

    return habitObj;
}
static void SaveHabitsJSON(const HabitCollection* collection) {
   if (!collection) return;

   StorageConfig storage_config;
   determine_storage_directory(&storage_config);

   cJSON* root = cJSON_CreateObject();
   cJSON_AddNumberToObject(root, "active_habit_id", collection->active_habit_id);
   
   cJSON* habits = cJSON_CreateArray();
   for (size_t i = 0; i < collection->habits_count; i++) {
       cJSON* habit = HabitToJSON(&collection->habits[i], collection);
       cJSON_AddItemToArray(habits, habit);
   }
   cJSON_AddItemToObject(root, "habits", habits);

   char* jsonStr = cJSON_Print(root);
   write_file_contents(storage_config.habits_path, jsonStr, strlen(jsonStr));

   free(jsonStr);
   cJSON_Delete(root);
}
static void LoadHabitFromJSON(Habit* habit, cJSON* habitObj, HabitCollection* collection) {
   habit->id = cJSON_GetObjectItem(habitObj, "id")->valueint;
   strncpy(habit->name, cJSON_GetObjectItem(habitObj, "name")->valuestring, MAX_HABIT_NAME - 1);
   
   cJSON* color = cJSON_GetObjectItem(habitObj, "color");
   habit->color.r = cJSON_GetObjectItem(color, "r")->valuedouble;
   habit->color.g = cJSON_GetObjectItem(color, "g")->valuedouble;
   habit->color.b = cJSON_GetObjectItem(color, "b")->valuedouble;
   habit->color.a = cJSON_GetObjectItem(color, "a")->valuedouble;

   // Load start_date if it exists, otherwise set to current time
   cJSON* start_date = cJSON_GetObjectItem(habitObj, "start_date");
   if (start_date) {
       habit->start_date = (time_t)start_date->valuedouble;
   } else {
       habit->start_date = time(NULL);
   }
    
    
   cJSON* days = cJSON_GetObjectItem(habitObj, "calendar_days");
   habit->days_count = 0;
   cJSON* day;
   cJSON_ArrayForEach(day, days) {
       if (habit->days_count >= MAX_CALENDAR_DAYS) break;
       
       HabitDay* habitDay = &habit->calendar_days[habit->days_count++];
       habitDay->date = cJSON_GetObjectItem(day, "date")->valueint;
       habitDay->day_index = cJSON_GetObjectItem(day, "day_index")->valueint;
       habitDay->completed = cJSON_IsTrue(cJSON_GetObjectItem(day, "completed"));
    }
    
    cJSON* collapsed = cJSON_GetObjectItem(habitObj, "collapsed_rows");
    collection->collapsed_rows_count = 0;
    if (collapsed) {
        cJSON* row;
        cJSON_ArrayForEach(row, collapsed) {
            if (collection->collapsed_rows_count >= MAX_CALENDAR_DAYS) break;
            collection->collapsed_rows[collection->collapsed_rows_count].row_index = 
                cJSON_GetObjectItem(row, "index")->valueint;
            collection->collapsed_rows[collection->collapsed_rows_count].is_collapsed = true;
            collection->collapsed_rows_count++;
        }
    }
}
static void CreateDefaultHabitsJSON(HabitCollection* defaultCollection) {
   Rocks_Theme base_theme = Rocks_GetTheme(GRocks);

   Habit* default_habit = &defaultCollection->habits[0];
   strncpy(default_habit->name, "Meditation", MAX_HABIT_NAME - 1);
   default_habit->id = 0;
   default_habit->color = base_theme.primary;
   default_habit->days_count = 0;

   // Set the start date to the most recent past Monday
   time_t now = time(NULL);
   struct tm *local_time = localtime(&now);
   struct tm start_date = *local_time;
   start_date.tm_hour = 0;
   start_date.tm_min = 0;
   start_date.tm_sec = 0;
   int days_to_monday = start_date.tm_wday == 0 ? 6 : start_date.tm_wday - 1;
   start_date.tm_mday -= days_to_monday;
   default_habit->start_date = mktime(&start_date);

   defaultCollection->habits_count = 1;
   defaultCollection->active_habit_id = 0;

   SaveHabitsJSON(defaultCollection);
}

static void LoadHabitsJSON(HabitCollection* collection) {
   StorageConfig storage_config;
   determine_storage_directory(&storage_config);

   long file_size;
   char* jsonStr = read_file_contents(storage_config.habits_path, &file_size);
   if (!jsonStr) {
       HabitCollection defaultCollection = {0};
       CreateDefaultHabitsJSON(&defaultCollection);
       *collection = defaultCollection;
       return;
   }

   cJSON* root = cJSON_Parse(jsonStr);
   free(jsonStr);

   if (!root) {
       HabitCollection defaultCollection = {0};
       CreateDefaultHabitsJSON(&defaultCollection);
       *collection = defaultCollection;
       return;
   }

   memset(collection, 0, sizeof(HabitCollection));
   collection->active_habit_id = cJSON_GetObjectItem(root, "active_habit_id")->valueint;
   
   cJSON* habits = cJSON_GetObjectItem(root, "habits");
   cJSON* habit;
   cJSON_ArrayForEach(habit, habits) {
       if (collection->habits_count >= MAX_HABITS) break;
       LoadHabitFromJSON(&collection->habits[collection->habits_count++], habit, collection);
   }

   cJSON_Delete(root);
}

#endif

void DeleteHabit(HabitCollection* collection, uint32_t habit_id) {
   if (!collection) return;
   #ifdef __EMSCRIPTEN__
       deleteHabitFunction(collection, habit_id);
       JS_LoadHabits(collection);
   #else
       // Find the habit index
       int delete_index = -1;
       for (size_t i = 0; i < collection->habits_count; i++) {
           if (collection->habits[i].id == habit_id) {
               delete_index = i;
               break;
           }
       }
       
       if (delete_index == -1) return;
       
       // Shift remaining habits left and update their IDs
       for (size_t i = delete_index; i < collection->habits_count - 1; i++) {
           collection->habits[i] = collection->habits[i + 1];
           collection->habits[i].id = i;  // Update ID to match new position
       }
       collection->habits_count--;
       
       // If we deleted the active habit, switch to the previous habit if possible
       if (collection->active_habit_id == habit_id) {
           if (collection->habits_count > 0) {
               if (delete_index > 0) {
                   // Switch to previous habit
                   collection->active_habit_id = delete_index - 1;
               } else {
                   // If we deleted first habit, switch to new first habit
                   collection->active_habit_id = 0;
               }
           }
       } else if (collection->active_habit_id > habit_id) {
           // If active habit was after deleted habit, update its ID
           collection->active_habit_id--;
       }
       
       SaveHabits(collection);
   #endif
}


void AddNewHabit(HabitCollection* collection) {
   if (!collection || collection->habits_count >= MAX_HABITS) return;
       
   #ifdef __EMSCRIPTEN__
       addNewHabitFunction(collection);
       JS_LoadHabits(collection); // Reload the collection after adding
   #else
       Rocks_Theme base_theme = Rocks_GetTheme(GRocks);

       Habit* new_habit = &collection->habits[collection->habits_count];
       snprintf(new_habit->name, MAX_HABIT_NAME, "Habit %zu", collection->habits_count + 1);
       new_habit->id = collection->habits_count;  // ID matches position
       new_habit->color = base_theme.primary;
       new_habit->days_count = 0;

       // Set the start date to the current time
       new_habit->start_date = time(NULL);
       
       collection->habits_count++;
       collection->active_habit_id = new_habit->id;
       
       SaveHabits(collection);
   #endif
}

void SaveHabits(HabitCollection* collection) {
   if (!collection) return;

   #ifdef __EMSCRIPTEN__
       JS_SaveHabits(collection);
   #else
       SaveHabitsJSON(collection);
   #endif
}

void LoadHabits(HabitCollection* collection) {
   Rocks_Theme base_theme = Rocks_GetTheme(GRocks);

   if (!collection) return;

   // Save the text input pointer and edit state before loading
   Rocks_TextInput* saved_input = collection->habit_name_input;
   bool saved_editing_state = collection->is_editing_new_habit;
   uint32_t saved_active_id = collection->active_habit_id;

   #ifdef __EMSCRIPTEN__
       JS_LoadHabits(collection);
   #else
       LoadHabitsJSON(collection);
   #endif

   // Restore the saved values
   collection->habit_name_input = saved_input;
   collection->is_editing_new_habit = saved_editing_state;
   collection->active_habit_id = saved_active_id;

   // Initialize default habit if none exists
   if (collection->habits_count == 0) {
       Habit* default_habit = &collection->habits[0];
       strncpy(default_habit->name, "Meditation", MAX_HABIT_NAME - 1);
       default_habit->id = 0;
       default_habit->color = base_theme.primary;
       default_habit->days_count = 0;
       collection->habits_count = 1;
       collection->active_habit_id = 0;
   }
}

bool IsHabitCompletedForDate(const Habit* habit, time_t date) {
   // Normalize input date to midnight
   struct tm tmp = *localtime(&date);
   tmp.tm_hour = 0;
   tmp.tm_min = 0;
   tmp.tm_sec = 0;
   time_t normalized_date = mktime(&tmp);
   
   for (size_t i = 0; i < habit->days_count; i++) {
       // Normalize stored date to midnight
       struct tm stored = *localtime(&habit->calendar_days[i].date);
       stored.tm_hour = 0;
       stored.tm_min = 0;
       stored.tm_sec = 0;
       time_t stored_date = mktime(&stored);
       
       if (stored_date == normalized_date && habit->calendar_days[i].completed) {
           return true;
       }
   }
   return false;
}

bool ToggleHabitDay(HabitCollection* collection, uint32_t day_index) {
   if (!collection) return false;
   
   #ifndef __EMSCRIPTEN__
   // Add debounce check using Rocks_GetTime
   float currentTime = Rocks_GetTime(GRocks);
   if (currentTime - lastCalendarToggleTime < CALENDAR_TOGGLE_DEBOUNCE_MS) {
       printf("Calendar toggle ignored - too soon (delta: %f s)", 
               currentTime - lastCalendarToggleTime);
       return false;
   }
   lastCalendarToggleTime = currentTime;
   #endif
   
   Habit* habit = GetActiveHabit(collection);
   if (!habit) return false;
   
   for (size_t i = 0; i < habit->days_count; i++) {
       if (habit->calendar_days[i].day_index == day_index) {
           habit->calendar_days[i].completed = !habit->calendar_days[i].completed;
           habit->calendar_days[i].date = time(NULL);
           return true;
       }
   }

   if (habit->days_count >= MAX_CALENDAR_DAYS) return false;
   
   HabitDay* new_day = &habit->calendar_days[habit->days_count++];
   new_day->day_index = day_index;
   new_day->completed = true;
   new_day->date = time(NULL);
   return true;
}

void UpdateCalendarStartDate(HabitCollection* collection, time_t new_start_date) {
   if (!collection) return;
   
   Habit* habit = GetActiveHabit(collection);
   if (habit) {
       habit->start_date = new_start_date;
       SaveHabits(collection);
   }
}

void UpdateHabitColor(HabitCollection* collection, Clay_Color color) {
   if (!collection) return;
   
   Habit* habit = GetActiveHabit(collection);
   if (habit) {
       habit->color = color;
       SaveHabits(collection);
   }
}

Habit* GetActiveHabit(HabitCollection* collection) {
   return GetHabitById(collection, collection->active_habit_id);
}

Habit* GetHabitById(HabitCollection* collection, uint32_t id) {
   if (!collection) return NULL;
   
   for (size_t i = 0; i < collection->habits_count; i++) {
       if (collection->habits[i].id == id) {
           return &collection->habits[i];
       }
   }
   
   return NULL;
}