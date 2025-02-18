#include "habits.h"
#include "habit_delete_modal.h"

HabitCollection habits = {0};

typedef struct {
    const char* url;
    Clay_Dimensions dimensions;
} HabitIcon;

static HabitIcon HABIT_ICONS[] = {
    {.url = "images/icons/check.svg", .dimensions = {24, 24}},
    {.url = "images/icons/edit.svg", .dimensions = {24, 24}},
    {.url = "images/icons/trash.svg", .dimensions = {24, 24}},
    {.url = "images/icons/emoji-look-up.svg", .dimensions = {24, 24}},
    {.url = "images/icons/emoji-look-down.svg", .dimensions = {24, 24}}
};

static void* habit_icon_images[5] = {NULL};

void InitializeHabitIcons(Rocks* rocks) {
    for (int i = 0; i < 5; i++) {
        if (habit_icon_images[i]) {
            Rocks_UnloadImage(rocks, habit_icon_images[i]);
            habit_icon_images[i] = NULL;
        }

        habit_icon_images[i] = Rocks_LoadImage(rocks, HABIT_ICONS[i].url);
        if (!habit_icon_images[i]) {
            fprintf(stderr, "Failed to load habit icon %s\n", HABIT_ICONS[i].url);
            continue;
        }
    }
}

void CleanupHabitIcons(Rocks* rocks) {
    for (int i = 0; i < 5; i++) {
        if (habit_icon_images[i]) {
            Rocks_UnloadImage(rocks, habit_icon_images[i]);
            habit_icon_images[i] = NULL;
        }
    }
}

static void HandleEditButtonClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        habits.is_editing_new_habit = true;
        
        if (habits.habit_name_input) {
            Habit* active_habit = GetActiveHabit(&habits);
            if (active_habit) {
                Rocks_SetTextInputText(habits.habit_name_input, active_habit->name);
            }
        }
        #ifdef CLAY_MOBILE
        Rocks_StartTextInput();
        #endif
    }
}



void HandleHeaderTitleClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state != CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        return;
    }

    Habit* active_habit = GetActiveHabit(&habits);
    if (!active_habit) {
        return;
    }
}

void HandleHabitNameSubmit(const char* text) {
    if (!text) return;  // Add null check
    
    Habit* active_habit = GetActiveHabit(&habits);
    if (!active_habit) return;

    if (text[0] != '\0') {
        for (size_t i = 0; i < habits.habits_count; i++) {
            if (habits.habits[i].id == habits.active_habit_id) {
                strncpy(habits.habits[i].name, text, sizeof(habits.habits[i].name) - 1);
                habits.habits[i].name[sizeof(habits.habits[i].name) - 1] = '\0';
                break;
            }
        }
        habits.is_editing_new_habit = false;
        SaveHabits(&habits);

        if (habits.habit_name_input) {
            Rocks_ClearTextInput(habits.habit_name_input);
        }

        #ifndef __EMSCRIPTEN__
        Rocks_StopTextInput();
        #endif
    }
}

static void HandleConfirmButtonClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        HandleHabitNameSubmit(Rocks_GetTextInputText(habits.habit_name_input));
        #ifdef CLAY_MOBILE
        Rocks_StopTextInput();
        #endif
    }
}
void HandleNewTabInteraction(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        printf("Adding new habit...\n"); // Debug print
        
        AddNewHabit(&habits);
        habits.is_editing_new_habit = true;
        habits.active_habit_id = habits.habits[habits.habits_count - 1].id;
        
        if (habits.habit_name_input) {
            Rocks_SetTextInputText(habits.habit_name_input, "");
            printf("Set text input to empty\n"); // Debug print
        }
        
        SaveHabits(&habits);
        printf("New habit added and saved. Count: %zu\n", habits.habits_count); // Debug print
    }
}

void HandleTabInteraction(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        uint32_t habit_id = (uint32_t)userData;
        habits.is_editing_new_habit = false;
        habits.active_habit_id = habit_id;
        SaveHabits(&habits);
    }
}
void ToggleHabitStateForDay(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        // Cast back to CalendarBoxProps pointer
        CalendarBoxProps* unique_props = (CalendarBoxProps*)userData;

        if (unique_props) {
            printf("Toggling habit state for date: %ld\n", (long)unique_props->date);

            if (unique_props->date == 0) {
                printf("Error: Invalid date\n");
                free(unique_props);
                return;
            }

            ToggleHabitDay(&habits, unique_props->date);
            SaveHabits(&habits);

            // Free the dynamically allocated props
            free(unique_props);
        }
    }
}

void HandleColorChange(Clay_Color new_color) {
    UpdateHabitColor(&habits, new_color);
}

void RenderHabitTab(const Habit* habit) {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    bool isActive = habits.active_habit_id == habit->id;
    
    CLAY({
        .id = CLAY_IDI("HabitTab", habit->id),
        .layout = {
            .padding = CLAY_PADDING_ALL(16),
            .childAlignment = { .y = CLAY_ALIGN_Y_CENTER },
            .sizing = { 
                .width = CLAY_SIZING_FIT(0),
                .height = CLAY_SIZING_FIXED(32)
            }
        },
        .backgroundColor = isActive ? base_theme.primary : 
                          (Clay_Hovered() ? base_theme.primary_hover : base_theme.background),
        .cornerRadius = CLAY_CORNER_RADIUS(5)
    }) {
        Clay_OnHover(HandleTabInteraction, habit->id);
        
        Clay_String habit_str = {
            .length = strlen(habit->name),
            .chars = habit->name
        };
        CLAY_TEXT(habit_str, CLAY_TEXT_CONFIG({
            .fontSize = 14,
            .fontId = FONT_ID_BODY_14,
            .textColor = base_theme.text,
            .wrapMode = CLAY_TEXT_WRAP_NONE
        }));
    }
}

void RenderHabitHeader() {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    Habit* active_habit = GetActiveHabit(&habits);
    if (!active_habit) return;

    bool isEditing = habits.is_editing_new_habit;

    CLAY({
        .id = CLAY_ID("HabitHeader"),
        .layout = {
            .padding = CLAY_PADDING_ALL(16),
            .childGap = 16,
            .layoutDirection = CLAY_LEFT_TO_RIGHT,
            .childAlignment = { 
                .x = CLAY_ALIGN_X_CENTER,
                .y = CLAY_ALIGN_Y_CENTER 
            },
            .sizing = {
                .width = CLAY_SIZING_FIT(0),
                .height = CLAY_SIZING_FIT(0)
            }
        },
        .backgroundColor = base_theme.background
    }) {
        CLAY({
            .id = CLAY_ID("ColorPickerContainer"),
            .layout = {
                .childGap = 0,
                .layoutDirection = CLAY_LEFT_TO_RIGHT,
                .padding = { 8, 8, 0, 0 },
                .childAlignment = { 
                    .x = CLAY_ALIGN_X_CENTER,
                    .y = CLAY_ALIGN_Y_CENTER 
                }
            }
        }) {
            RenderColorPicker(active_habit->color, HandleColorChange);
            if (IsDeleteModalOpen()) {
                RenderDeleteHabitModal();
            }
        }
        if (isEditing) {
            CLAY({
                .layout = {
                    .sizing = {
                        .width = CLAY_SIZING_FIXED(200),
                        .height = CLAY_SIZING_FIT(0)
                    }
                }
            }) {
                Rocks_RenderTextInput(habits.habit_name_input, active_habit->id);
            }

            CLAY({
                .layout = {
                    .childGap = 8,
                    .layoutDirection = CLAY_LEFT_TO_RIGHT
                }
            }) {
                // Delete button
                CLAY({
                    .id = CLAY_ID("DeleteButton"),
                    .layout = {
                        .sizing = {
                            .width = CLAY_SIZING_FIXED(32),
                            .height = CLAY_SIZING_FIXED(32)
                        },
                        .childAlignment = {
                            .x = CLAY_ALIGN_X_CENTER,
                            .y = CLAY_ALIGN_Y_CENTER
                        }
                    },
                    .backgroundColor = Clay_Hovered() ? theme->danger : base_theme.background,
                    .cornerRadius = CLAY_CORNER_RADIUS(4)
                }) {
                    Clay_OnHover(HandleDeleteButtonClick, active_habit->id);
                    
                    CLAY({
                        .layout = {
                            .sizing = {
                                .width = CLAY_SIZING_FIXED(24),
                                .height = CLAY_SIZING_FIXED(24)
                            }
                        },
                        .image = {
                            .sourceDimensions = HABIT_ICONS[2].dimensions,
                            .imageData = habit_icon_images[2]
                        }
                    }) {}
                }

                // Confirm button
                CLAY({
                    .id = CLAY_ID("ConfirmButton"),
                    .layout = {
                        .sizing = {
                            .width = CLAY_SIZING_FIXED(32),
                            .height = CLAY_SIZING_FIXED(32)
                        },
                        .childAlignment = {
                            .x = CLAY_ALIGN_X_CENTER,
                            .y = CLAY_ALIGN_Y_CENTER
                        }
                    },
                    .backgroundColor = Clay_Hovered() ? theme->success : base_theme.secondary,
                    .cornerRadius = CLAY_CORNER_RADIUS(4)
                }) {
                    Clay_OnHover(HandleConfirmButtonClick, 0);
                    
                    CLAY({
                        .layout = {
                            .sizing = {
                                .width = CLAY_SIZING_FIXED(24),
                                .height = CLAY_SIZING_FIXED(24)
                            }
                        },
                        .image = {
                            .sourceDimensions = HABIT_ICONS[0].dimensions,
                            .imageData = habit_icon_images[0]
                        }
                    }) {}
                }
            }
            
        } else {
            
            Clay_String active_name = {
                .length = strlen(active_habit->name),
                .chars = active_habit->name
            };
            CLAY_TEXT(active_name, CLAY_TEXT_CONFIG({
                .fontSize = 24,
                .fontId = FONT_ID_BODY_24,
                .textColor = base_theme.text
            }));

            // Edit button
            CLAY({
                .id = CLAY_ID("EditButton"),
                .layout = {
                    .sizing = {
                        .width = CLAY_SIZING_FIXED(32),
                        .height = CLAY_SIZING_FIXED(32)
                    },
                    .childAlignment = {
                        .x = CLAY_ALIGN_X_CENTER,
                        .y = CLAY_ALIGN_Y_CENTER
                    }
                },
                .backgroundColor = Clay_Hovered() ? base_theme.primary_hover : base_theme.background,
                .cornerRadius = CLAY_CORNER_RADIUS(4)
            }) {
                Clay_OnHover(HandleEditButtonClick, 0);
                
                CLAY({
                    .layout = {
                        .sizing = {
                            .width = CLAY_SIZING_FIXED(24),
                            .height = CLAY_SIZING_FIXED(24)
                        }
                    },
                    .image = {
                        .sourceDimensions = HABIT_ICONS[1].dimensions,
                        .imageData = habit_icon_images[1]
                    }
                }) {}
            }
        }   
    
    }
}
void RenderHabitTabBar() {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    CLAY({
        .id = CLAY_ID("HabitTabsContainer"),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_GROW(),
                .height = CLAY_SIZING_FIXED(62)
            },
            .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
        },
        .backgroundColor = base_theme.secondary
    }) {
        CLAY({
            .id = CLAY_ID("HabitTabs"),
            .layout = {
                .sizing = {
                    .width = CLAY_SIZING_FIT(),
                    .height = CLAY_SIZING_GROW()
                },
                .childGap = 8,
                .padding = CLAY_PADDING_ALL(16),
                .childAlignment = { 
                    .x = CLAY_ALIGN_X_CENTER,
                    .y = CLAY_ALIGN_Y_CENTER 
                },
                .layoutDirection = CLAY_LEFT_TO_RIGHT
            },
            .scroll = { .vertical = true }
        }) {
            for (size_t i = 0; i < habits.habits_count; i++) {
                RenderHabitTab(&habits.habits[i]);
            }

            // New tab button
            CLAY({
                .id = CLAY_ID("NewHabitTab"),
                .layout = {
                    .sizing = { 
                        .width = CLAY_SIZING_FIXED(32),
                        .height = CLAY_SIZING_FIXED(32)
                    },
                    .childAlignment = {
                        .x = CLAY_ALIGN_X_CENTER,
                        .y = CLAY_ALIGN_Y_CENTER
                    }
                },
                .backgroundColor = Clay_Hovered() ? base_theme.primary_hover : base_theme.background,
                .cornerRadius = CLAY_CORNER_RADIUS(5)
            }) {
                Clay_OnHover(HandleNewTabInteraction, 0);
                CLAY_TEXT(CLAY_STRING("+"), CLAY_TEXT_CONFIG({
                    .fontSize = 24,
                    .fontId = FONT_ID_BODY_24,
                    .textColor = base_theme.text
                }));
            }
        }
    }
}

void InitializeHabitsPage(Rocks* rocks) {
    if (!rocks) return;
    printf("Initializing habits page\n");
    
    // Clean up existing
    if (habits.habit_name_input) {
        Rocks_DestroyTextInput(habits.habit_name_input); 
        habits.habit_name_input = NULL;
    }
    
    LoadHabits(&habits);
    printf("Creating text input\n");
    habits.habit_name_input = Rocks_CreateTextInput(NULL, HandleHabitNameSubmit);
    printf("Text input: %p\n", (void*)habits.habit_name_input);

    InitializeHabitIcons(rocks);
    InitializeDeleteModal();
}
void CleanupHabitsPage(Rocks* rocks) {
    printf("Cleaning up habits page\n");
    if (habits.habit_name_input) {
        printf("Destroying text input\n");
        Rocks_DestroyTextInput(habits.habit_name_input);
        habits.habit_name_input = NULL;
    }
    CleanupDeleteModal();
    CleanupHabitIcons(rocks);
    CleanupColorPicker();
    memset(&habits, 0, sizeof(habits));
}


static void HandleCalendarExpand(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        if (!habits.is_calendar_expanded) {
            habits.is_calendar_expanded = true;
            habits.extra_weeks = 2;
        } else {
            habits.extra_weeks += 2; 
        }
        SaveHabits(&habits);
    }
}


static void HandleCalendarCollapse(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        habits.is_calendar_expanded = false;
        habits.extra_weeks = 0;
        SaveHabits(&habits);
    }
}

void RenderHabitsPage(float dt) {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    LoadHabits(&habits);
    Habit* active_habit = GetActiveHabit(&habits);
    if (!active_habit) return;

    if (habits.habit_name_input && habits.is_editing_new_habit) {
        Rocks_UpdateTextInputFromRocksInput(habits.habit_name_input, GRocks->input, dt);
    }
    
    time_t now;
    time(&now);

    struct tm today_midnight = *localtime(&now);
    today_midnight.tm_hour = 0;
    today_midnight.tm_min = 0;
    today_midnight.tm_sec = 0;
    time_t today_timestamp = mktime(&today_midnight);

    struct tm start_date = today_midnight;
    start_date.tm_mday -= (14 + (habits.is_calendar_expanded ? habits.extra_weeks * 7 : 0));
    mktime(&start_date);

    struct tm end_date = today_midnight;
    end_date.tm_mday += 21; // Show 3 weeks into the future
    mktime(&end_date);

    static const char *day_labels[] = {"S", "M", "T", "W", "T", "F", "S"};

    CLAY({
        .id = CLAY_ID("HabitsContainer"),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_GROW(),
                .height = CLAY_SIZING_GROW()
            },
            .layoutDirection = CLAY_TOP_TO_BOTTOM,
            .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
        }
    }) {
        RenderHabitTabBar();
        RenderHabitHeader();

        // Day labels
        CLAY({
            .id = CLAY_ID("DayLabels"),
            .layout = {
                .sizing = {
                    .width = CLAY_SIZING_GROW(),
                    .height = CLAY_SIZING_FIT(0)
                },
                .padding = { 0, 0, 8, 8 },
                .childGap = 8,
                .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
            }
        }) {
            float screenWidth = (float)windowWidth;
            const float MAX_LABEL_WIDTH = 90.0f;
            const float MIN_LABEL_WIDTH = 32.0f;
            float labelWidth = screenWidth * 0.1f;
            labelWidth = fmaxf(MIN_LABEL_WIDTH, fminf(labelWidth, MAX_LABEL_WIDTH));
            int labelFontSize = (int)(labelWidth * 0.25f);

            for (int i = 0; i < 7; i++) {
                CLAY({
                    .id = CLAY_IDI("DayLabel", i),
                    .layout = {
                        .sizing = { 
                            .width = CLAY_SIZING_FIXED(labelWidth),
                            .height = CLAY_SIZING_FIT(0)
                        },
                        .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
                    }
                }) {
                    Clay_String day_str = {
                        .length = strlen(day_labels[i]),
                        .chars = day_labels[i]
                    };
                    CLAY_TEXT(day_str, CLAY_TEXT_CONFIG({
                        .fontSize = labelFontSize,
                        .fontId = FONT_ID_BODY_24,
                        .textColor = base_theme.text
                    }));
                }
            }
        }

        CLAY({
            .id = CLAY_ID("CalendarScrollContainer"),
            .layout = {
                .sizing = {
                    .width = CLAY_SIZING_GROW(),
                    .height = CLAY_SIZING_FIT(0)
                },
                .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
            },
            .scroll = { .vertical = true }
        }) {
            CLAY({
                .id = CLAY_ID("CalendarGrid"),
                .layout = {
                    .sizing = {
                        .width = CLAY_SIZING_FIT(0),
                        .height = CLAY_SIZING_FIT(0)
                    },
                    .childGap = 32,
                    .layoutDirection = CLAY_TOP_TO_BOTTOM,
                    .padding = CLAY_PADDING_ALL(16)
                }
            }) {
                time_t start_time = mktime(&start_date);
                time_t end_time = mktime(&end_date);
                int total_days = (int)((end_time - start_time) / (60 * 60 * 24)) + 1;
                int total_weeks = (total_days + 6) / 7;

                struct tm current = start_date;
                

                if (habits.is_calendar_expanded) {
                    CLAY({
                        .id = CLAY_ID("TopExpandButton"),
                        .layout = {
                            .sizing = {
                                .width = CLAY_SIZING_GROW(),
                                .height = CLAY_SIZING_GROW()
                            },
                            .childAlignment = {
                                .x = CLAY_ALIGN_X_CENTER,
                                .y = CLAY_ALIGN_Y_CENTER
                            }
                        },
                        .backgroundColor = Clay_Hovered() ? base_theme.primary_hover : base_theme.background,
                        .cornerRadius = CLAY_CORNER_RADIUS(4)
                    }) {
                        Clay_OnHover(HandleCalendarExpand, 0);
                        CLAY({
                            .layout = {
                                .sizing = {
                                    .width = CLAY_SIZING_FIXED(24),
                                    .height = CLAY_SIZING_FIXED(24)
                                }
                            },
                            .image = {
                                .sourceDimensions = HABIT_ICONS[3].dimensions,
                                .imageData = habit_icon_images[3]
                            }
                        }) {}
                    }
                }
                
                for (int row = 0; row < total_weeks; row++) {
                    if ((row == 0 && !habits.is_calendar_expanded) || (row == 2 && habits.is_calendar_expanded)) {
                        Clay_ElementId toggleButtonId = habits.is_calendar_expanded ? 
                            CLAY_ID("CollapsePastRowsButton") : CLAY_ID("ExpandPastRowsButton");
                        
                        CLAY({
                            .id = toggleButtonId,
                            .layout = {
                                .sizing = {
                                    .width = CLAY_SIZING_GROW(),
                                    .height = CLAY_SIZING_GROW()
                                },
                                .childAlignment = {
                                    .x = CLAY_ALIGN_X_CENTER,
                                    .y = CLAY_ALIGN_Y_CENTER
                                }
                            },
                            .backgroundColor = Clay_Hovered() ? base_theme.primary_hover : base_theme.background,
                            .cornerRadius = CLAY_CORNER_RADIUS(4),
                        }) {
                            Clay_OnHover(habits.is_calendar_expanded ? HandleCalendarCollapse : HandleCalendarExpand, 0);
                            CLAY({
                                .layout = {
                                    .sizing = {
                                        .width = CLAY_SIZING_FIXED(24),
                                        .height = CLAY_SIZING_FIXED(24)
                                    }
                                },
                                .image = {
                                    .sourceDimensions = HABIT_ICONS[habits.is_calendar_expanded ? 4 : 3].dimensions,
                                    .imageData = habit_icon_images[habits.is_calendar_expanded ? 4 : 3]
                                }
                            }) {}
                        }
                    }
                    CLAY({
                        .id = CLAY_IDI("WeekRow", row),
                        .layout = {
                            .sizing = {
                                .width = CLAY_SIZING_GROW(),
                                .height = CLAY_SIZING_FIT(0)
                            },
                            .childGap = 10,
                            .layoutDirection = CLAY_LEFT_TO_RIGHT,
                            .childAlignment = { .y = CLAY_ALIGN_Y_CENTER }
                        }
                    }) {
                        for (int col = 0; col < 7; col++) {
                            time_t current_timestamp = mktime(&current);
                            bool is_today = (current_timestamp == today_timestamp);
                            bool is_past = (current_timestamp < today_timestamp);
                            bool is_completed = IsHabitCompletedForDate(active_habit, current_timestamp);

                            CalendarBoxProps props = {
                                .day_number = current.tm_mday,
                                .is_today = is_today,
                                .is_past = is_past,
                                .is_completed = is_completed,
                                .on_click = ToggleHabitStateForDay,
                                .custom_color = active_habit->color,
                                .date = current_timestamp
                            };
                            RenderCalendarBox(props);

                            current.tm_mday++;
                            mktime(&current);
                        }
                    }
                }
            }
        }
    }
     // After rendering, check if we need to do initial scroll
    if (!habits.has_done_initial_scroll) {
        Clay_ScrollContainerData scroll_data = Clay_GetScrollContainerData(CLAY_ID("CalendarScrollContainer"));
        if (scroll_data.found && scroll_data.scrollPosition) {
            scroll_data.scrollPosition->y = -42; // One row height
            habits.has_done_initial_scroll = true;
            SaveHabits(&habits);
        }
    }
}