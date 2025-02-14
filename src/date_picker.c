#include <stdio.h>
#include <string.h>

#include "date_picker.h"
#include "rocks.h"
#include "quest_theme.h"

static void (*g_date_change_callback)(time_t) = NULL;
static Rocks_Modal* g_modal = NULL;
static struct tm g_editing_date = {0};
    
static const char* month_names[] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

void InitializeDatePicker(time_t initial_date, void (*on_date_change)(time_t)) {
    g_date_change_callback = on_date_change;
    
    // Create the modal with specific dimensions
    g_modal = Rocks_CreateModal(400, 500, NULL, NULL);
    
    struct tm* temp = localtime(&initial_date);
    if (temp) {
        g_editing_date = *temp;
        mktime(&g_editing_date);
    }
}

static void HandleDateClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        Rocks_OpenModal(g_modal);
    }
}

static void HandleDayChange(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        int change = (int)userData;
        g_editing_date.tm_mday += change;
        mktime(&g_editing_date);
    }
}

static void HandleMonthChange(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        int change = (int)userData;
        g_editing_date.tm_mon += change;
        mktime(&g_editing_date);
    }
}

static void HandleYearChange(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        int change = (int)userData;
        g_editing_date.tm_year += change;
        mktime(&g_editing_date);
    }
}

static void HandleSaveDate(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        if (g_date_change_callback) {
            time_t new_date = mktime(&g_editing_date);
            g_date_change_callback(new_date);
        }
        Rocks_CloseModal(g_modal);
    }
}

static void RenderDatePickerContent(void) {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    static char year_str[16];
    static char month_str[32];
    static char day_str[16];
    // Convert year
    {
        int year = 1900 + g_editing_date.tm_year;
        int index = 0;
        int temp_year = year;
        int digits[4] = {0};
        int digit_count = 0;
        
        while (temp_year > 0) {
            digits[digit_count++] = temp_year % 10;
            temp_year /= 10;
        }
        
        for (int i = digit_count - 1; i >= 0; i--) {
            year_str[index++] = digits[i] + '0';
        }
        year_str[index] = '\0';
    }
    
    // Convert month
    {
        int month_index = g_editing_date.tm_mon;
        if (month_index < 0) month_index = 0;
        if (month_index > 11) month_index = 11;
        
        const char* month_name = month_names[month_index];
        size_t i = 0;
        while (month_name[i] && i < sizeof(month_str) - 1) {
            month_str[i] = month_name[i];
            i++;
        }
        month_str[i] = '\0';
    }
    
    // Convert day
    {
        int day = g_editing_date.tm_mday;
        int index = 0;
        int temp_day = day;
        int digits[2] = {0};
        int digit_count = 0;
        
        while (temp_day > 0) {
            digits[digit_count++] = temp_day % 10;
            temp_day /= 10;
        }
        
        for (int i = digit_count - 1; i >= 0; i--) {
            day_str[index++] = digits[i] + '0';
        }
        day_str[index] = '\0';
    }

    CLAY({
        .id = CLAY_ID("DatePickerModal"),
        .layout = {
            .sizing = { CLAY_SIZING_GROW(), CLAY_SIZING_GROW() },
            .childGap = 20,
            .layoutDirection = CLAY_TOP_TO_BOTTOM,
            .padding = CLAY_PADDING_ALL(20)
        }
    }) {
        CLAY_TEXT(CLAY_STRING("Select Date"), 
            CLAY_TEXT_CONFIG({
                .fontSize = 24,
                .textColor = base_theme.text
            })
        );

        // Year selector
        CLAY({
            .layout = {
                .childGap = 10,
                .layoutDirection = CLAY_LEFT_TO_RIGHT
            }
        }) {
            CLAY_TEXT(CLAY_STRING("Year:"), 
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .textColor = base_theme.text
                })
            );
            
            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(10)
                },
                .backgroundColor = base_theme.secondary
            }) {
                Clay_OnHover(HandleYearChange, -1);
                CLAY_TEXT(CLAY_STRING("-"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }
            Clay_String yearString = {
                .chars = year_str,
                .length = strlen(year_str)
            };

            CLAY_TEXT(yearString, 
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .textColor = base_theme.text
                })
            );

            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(10)
                },
                .backgroundColor = base_theme.secondary
            }) {
                Clay_OnHover(HandleYearChange, 1);
                CLAY_TEXT(CLAY_STRING("+"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }
        }

        // Month selector
        CLAY({
            .layout = {
                .childGap = 10,
                .layoutDirection = CLAY_LEFT_TO_RIGHT
            }
        }) {
            CLAY_TEXT(CLAY_STRING("Month:"), 
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .textColor = base_theme.text
                })
            );
            
            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(10)
                },
                .backgroundColor = base_theme.secondary
            }) {
                Clay_OnHover(HandleMonthChange, -1);
                CLAY_TEXT(CLAY_STRING("-"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }

            Clay_String monthString = {
                .chars = month_str,
                .length = strlen(month_str)
            };

            CLAY_TEXT(monthString,
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .textColor = base_theme.text
                })
            );

            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(10)
                },
                .backgroundColor = base_theme.secondary
            }) {
                Clay_OnHover(HandleMonthChange, 1);
                CLAY_TEXT(CLAY_STRING("+"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }
        }

        // Day selector
        CLAY({
            .layout = {
                .childGap = 10,
                .layoutDirection = CLAY_LEFT_TO_RIGHT
            }
        }) {
            CLAY_TEXT(CLAY_STRING("Day:"), 
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .textColor = base_theme.text
                })
            );
            
            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(10)
                },
                .backgroundColor = base_theme.secondary
            }) {
                Clay_OnHover(HandleDayChange, -1);
                CLAY_TEXT(CLAY_STRING("-"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }

            Clay_String dayString = {
                .chars = day_str,
                .length = strlen(day_str)
            };

            CLAY_TEXT(dayString,
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .textColor = base_theme.text
                })
            );

            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(10)
                },
                .backgroundColor = base_theme.secondary
            }) {
                Clay_OnHover(HandleDayChange, 1);
                CLAY_TEXT(CLAY_STRING("+"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }
        }

        // Save button
        CLAY({
            .layout = {
                .padding = CLAY_PADDING_ALL(10)
            }
        }) {
            CLAY({
                .layout = {
                    .padding = CLAY_PADDING_ALL(20)
                },
                .backgroundColor = base_theme.primary,
                .cornerRadius = CLAY_CORNER_RADIUS(8)
            }) {
                Clay_OnHover(HandleSaveDate, 0);
                CLAY_TEXT(CLAY_STRING("Save"), 
                    CLAY_TEXT_CONFIG({
                        .fontSize = 18,
                        .textColor = base_theme.text
                    })
                );
            }
        }
    }
}

void RenderDatePicker(time_t current_date, void (*on_date_change)(time_t)) {
    if (!g_modal) {
        InitializeDatePicker(current_date, on_date_change);
    }

    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    static char date_str[32] = {0};
    struct tm* current_tm = localtime(&current_date);

    if (current_tm) {
        snprintf(date_str, sizeof(date_str), "%d %s %d", 
            current_tm->tm_mday, 
            (current_tm->tm_mon < 12) ? month_names[current_tm->tm_mon] : "Invalid",
            1900 + current_tm->tm_year);
    } else {
        strcpy(date_str, "Invalid Date");
    }

    Clay_String dateString = {
        .chars = date_str,
        .length = strlen(date_str)
    };

    // Render the date picker button
    CLAY({
        .id = CLAY_ID("DatePickerContainer"),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_FIT(),
                .height = CLAY_SIZING_FIT()
            },
            .padding = CLAY_PADDING_ALL(16)
        }
    }) {
        CLAY({
            .id = CLAY_ID("DateDisplay"),
            .layout = {
                .padding = CLAY_PADDING_ALL(10)
            },
            .backgroundColor = base_theme.secondary,
            .cornerRadius = CLAY_CORNER_RADIUS(8)
        }) {
            Clay_OnHover(HandleDateClick, (intptr_t)g_modal);
            CLAY_TEXT(dateString,
                CLAY_TEXT_CONFIG({
                    .fontSize = 16,
                    .textColor = base_theme.text
                })
            );
        }
    }

    // Render the modal if it's open
    if (g_modal && g_modal->is_open) {
        Rocks_RenderModal(g_modal);
        RenderDatePickerContent();
    }
}

void CleanupDatePicker(void) {
    if (g_modal) {
        Rocks_DestroyModal(g_modal);
        g_modal = NULL;
    }
}