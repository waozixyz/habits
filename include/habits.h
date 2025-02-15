#ifndef HABITS_H
#define HABITS_H
#include <time.h>
#include <stdio.h>
#include <string.h>
#include "rocks.h"
#include "rocks_clay.h"
#include "habits_state.h"
#include "config.h"
#include "calendar_box.h"
#include "color_picker.h"
#include "config.h"
#include "utils.h"
#include "quest_theme.h"
#include "components/modal.h"
#include "components/text_input.h"

// Modal functions
void RenderDeleteHabitModal(void);
void RenderDeleteModalContent(void);

// Habit tab bar functions
void RenderHabitTabBar(void);
void HandleNewTabInteraction(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);
void HandleTabInteraction(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);
void HandleHabitNameSubmit(const char* text);

void InitializeHabitsPage(Rocks* rocks);

// Cleanup functions
void CleanupHabitsPage(Rocks* rocks);

// Event handling
void HandleHabitsPageInput(InputEvent event);
void ToggleHabitStateForDay(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);
void HandleViewMorePast(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);

// Main page render function
void RenderHabitsPage(float dt);

// External state
extern HabitCollection habits;

#endif // HABITS_H