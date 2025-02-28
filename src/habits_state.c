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

   cJSON* days = cJSON_CreateArray();
   for (size_t i = 0; i < habit->days_count; i++) {
       cJSON* day = cJSON_CreateObject();
       cJSON_AddNumberToObject(day, "date", habit->calendar_days[i].date);
       cJSON_AddBoolToObject(day, "completed", habit->calendar_days[i].completed);
       cJSON_AddItemToArray(days, day);
   }
   cJSON_AddItemToObject(habitObj, "calendar_days", days);

   return habitObj;
}
static void LoadHabitFromJSON(Habit* habit, cJSON* habitObj, HabitCollection* collection) {
   cJSON* id = cJSON_GetObjectItem(habitObj, "id");
   cJSON* name = cJSON_GetObjectItem(habitObj, "name");
   cJSON* color = cJSON_GetObjectItem(habitObj, "color");
   cJSON* days = cJSON_GetObjectItem(habitObj, "calendar_days");

   // Safe loading of required fields
   if (id && cJSON_IsNumber(id)) {
       habit->id = id->valueint;
   } else {
       habit->id = 0;
   }

   if (name && cJSON_IsString(name)) {
       strncpy(habit->name, name->valuestring, MAX_HABIT_NAME - 1);
       habit->name[MAX_HABIT_NAME - 1] = '\0';
   } else {
       strncpy(habit->name, "Unnamed Habit", MAX_HABIT_NAME - 1);
   }

   // Load color if it exists and is valid
   Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
   if (color && cJSON_IsObject(color)) {
       cJSON* r = cJSON_GetObjectItem(color, "r");
       cJSON* g = cJSON_GetObjectItem(color, "g");
       cJSON* b = cJSON_GetObjectItem(color, "b");
       cJSON* a = cJSON_GetObjectItem(color, "a");

       if (r && g && b && a) {
           habit->color.r = (float)cJSON_GetNumberValue(r);
           habit->color.g = (float)cJSON_GetNumberValue(g);
           habit->color.b = (float)cJSON_GetNumberValue(b);
           habit->color.a = (float)cJSON_GetNumberValue(a);
       } else {
           habit->color = base_theme.primary;
       }
   } else {
       habit->color = base_theme.primary;
   }

   // Load calendar days
   habit->days_count = 0;
   if (days && cJSON_IsArray(days)) {
       cJSON* day;
       cJSON_ArrayForEach(day, days) {
           if (habit->days_count >= MAX_CALENDAR_DAYS) break;
           cJSON* date = cJSON_GetObjectItem(day, "date");
           cJSON* completed = cJSON_GetObjectItem(day, "completed");

           if (date && completed) {
               HabitDay* habitDay = &habit->calendar_days[habit->days_count++];
               habitDay->date = (time_t)cJSON_GetNumberValue(date);
               habitDay->completed = cJSON_IsTrue(completed);
           }
       }
   }
}

static void SaveHabitsJSON(const HabitCollection* collection) {
    if (!collection) return;

    StorageConfig storage_config;
    determine_storage_directory(&storage_config);

    cJSON* root = cJSON_CreateObject();
    cJSON_AddNumberToObject(root, "active_habit_id", collection->active_habit_id);
    
    // Keep old fields for backward compatibility
    cJSON_AddBoolToObject(root, "is_calendar_expanded", collection->is_calendar_expanded);
    cJSON_AddNumberToObject(root, "extra_weeks", collection->extra_weeks);
    
    // Add new calendar offset field
    cJSON_AddNumberToObject(root, "calendar_offset_weeks", collection->calendar_offset_weeks);

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


bool ToggleHabitDay(HabitCollection* collection, time_t date) {
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
   
   // Look for an existing entry for this specific date
   for (size_t i = 0; i < habit->days_count; i++) {
       // Normalize both dates to midnight
       struct tm input_tm = *localtime(&date);
       input_tm.tm_hour = 0;
       input_tm.tm_min = 0;
       input_tm.tm_sec = 0;
       time_t normalized_input_date = mktime(&input_tm);

       struct tm stored_tm = *localtime(&habit->calendar_days[i].date);
       stored_tm.tm_hour = 0;
       stored_tm.tm_min = 0;
       stored_tm.tm_sec = 0;
       time_t normalized_stored_date = mktime(&stored_tm);

       // If we find a match, toggle its completion
       if (normalized_stored_date == normalized_input_date) {
           habit->calendar_days[i].completed = !habit->calendar_days[i].completed;
           habit->calendar_days[i].date = date;  // Update with the exact input date
           return true;
       }
   }

   // If no existing entry is found and we have space, add a new one
   if (habit->days_count >= MAX_CALENDAR_DAYS) return false;
   
   HabitDay* new_day = &habit->calendar_days[habit->days_count++];
   new_day->completed = true;
   new_day->date = date;  // Use the exact input date
   return true;
}



static void CreateDefaultHabitsJSON(HabitCollection* defaultCollection) {
   Rocks_Theme base_theme = Rocks_GetTheme(GRocks);

   Habit* default_habit = &defaultCollection->habits[0];
   strncpy(default_habit->name, "Meditation", MAX_HABIT_NAME - 1);
   default_habit->id = 0;
   default_habit->color = base_theme.primary;
   default_habit->days_count = 0;

   defaultCollection->habits_count = 1;
   defaultCollection->active_habit_id = 0;
   defaultCollection->calendar_offset_weeks = 0;  // Initialize new field

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
    
    cJSON* active_habit_id = cJSON_GetObjectItem(root, "active_habit_id");
    cJSON* is_calendar_expanded = cJSON_GetObjectItem(root, "is_calendar_expanded");
    cJSON* extra_weeks = cJSON_GetObjectItem(root, "extra_weeks");
    cJSON* calendar_offset_weeks = cJSON_GetObjectItem(root, "calendar_offset_weeks");

    if (active_habit_id && cJSON_IsNumber(active_habit_id)) {
        collection->active_habit_id = (uint32_t)cJSON_GetNumberValue(active_habit_id);
    }
    if (is_calendar_expanded && cJSON_IsBool(is_calendar_expanded)) {
        collection->is_calendar_expanded = cJSON_IsTrue(is_calendar_expanded);
    }
    if (extra_weeks && cJSON_IsNumber(extra_weeks)) {
        collection->extra_weeks = (int)cJSON_GetNumberValue(extra_weeks);
    }
    // Load new field if present
    if (calendar_offset_weeks && cJSON_IsNumber(calendar_offset_weeks)) {
        collection->calendar_offset_weeks = (int)cJSON_GetNumberValue(calendar_offset_weeks);
    } else {
        collection->calendar_offset_weeks = 0;  // Default to 0 if not found
    }

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
   int saved_calendar_offset = collection->calendar_offset_weeks;

   #ifdef __EMSCRIPTEN__
       JS_LoadHabits(collection);
   #else
       LoadHabitsJSON(collection);
   #endif

   // Restore the saved values
   collection->habit_name_input = saved_input;
   collection->is_editing_new_habit = saved_editing_state;
   collection->active_habit_id = saved_active_id;
   
   // Make sure the calendar offset is valid
   if (collection->calendar_offset_weeks < 0) {
       collection->calendar_offset_weeks = 0;
   }

   // Initialize default habit if none exists
   if (collection->habits_count == 0) {
       Habit* default_habit = &collection->habits[0];
       strncpy(default_habit->name, "Meditation", MAX_HABIT_NAME - 1);
       default_habit->id = 0;
       default_habit->color = base_theme.primary;
       default_habit->days_count = 0;
       collection->habits_count = 1;
       collection->active_habit_id = 0;
       collection->calendar_offset_weeks = 0;
   }
}

bool IsHabitCompletedForDate(const Habit* habit, time_t date) {
    if (!habit) return false;
    
    // Normalize input date to midnight
    struct tm normalized_tm = *localtime(&date);
    normalized_tm.tm_hour = 0;
    normalized_tm.tm_min = 0;
    normalized_tm.tm_sec = 0;
    time_t normalized_date = mktime(&normalized_tm);
    
    for (size_t i = 0; i < habit->days_count; i++) {
        // Normalize stored date to midnight
        struct tm stored_tm = *localtime(&habit->calendar_days[i].date);
        stored_tm.tm_hour = 0;
        stored_tm.tm_min = 0;
        stored_tm.tm_sec = 0;
        time_t stored_normalized_date = mktime(&stored_tm);
        
        if (stored_normalized_date == normalized_date && habit->calendar_days[i].completed) {
            return true;
        }
    }
    return false;
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