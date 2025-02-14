#include "habit_delete_modal.h"
#include "habits.h"

static Rocks_Modal* g_delete_habit_modal = NULL;
static uint32_t pending_delete_habit_id = 0;
static char pending_delete_habit_name[MAX_HABIT_NAME] = {0};

void InitializeDeleteModal(void) {
    g_delete_habit_modal = Rocks_CreateModal(300, 300, RenderDeleteModalContent, NULL);
}

void CleanupDeleteModal(void) {
    if (g_delete_habit_modal) {
        Rocks_DestroyModal(g_delete_habit_modal);
        g_delete_habit_modal = NULL;
    }
}

void HandleDeleteButtonClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        uint32_t habit_id = (uint32_t)userData;
        for (size_t i = 0; i < habits.habits_count; i++) {
            if (habits.habits[i].id == habit_id) {
                #ifdef CLAY_MOBILE
                Rocks_StopTextInput();
                #endif
                
                pending_delete_habit_id = habit_id;
                strncpy(pending_delete_habit_name, habits.habits[i].name, MAX_HABIT_NAME - 1);
                pending_delete_habit_name[MAX_HABIT_NAME - 1] = '\0';
                Rocks_OpenModal(g_delete_habit_modal);
                break;
            }
        }
    }
}

void HandleModalConfirm(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        DeleteHabit(&habits, pending_delete_habit_id);
        habits.is_editing_new_habit = false;  
        Rocks_CloseModal(g_delete_habit_modal);
    }
}

void HandleModalCancel(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        Rocks_CloseModal(g_delete_habit_modal);
    }
}

void RenderDeleteModalContent(void) {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    CLAY({
        .id = CLAY_ID("DeleteModalContent"),
        .layout = {
            .sizing = { CLAY_SIZING_GROW(), CLAY_SIZING_GROW() },
            .childGap = 24,
            .layoutDirection = CLAY_TOP_TO_BOTTOM
        }
    }) {
        CLAY_TEXT(CLAY_STRING("Delete Habit"), 
            CLAY_TEXT_CONFIG({
                .fontSize = 24,
                .fontId = FONT_ID_BODY_24,
                .textColor = base_theme.text
            })
        );

        CLAY_TEXT(CLAY_STRING("Are you sure you want to delete:"),
            CLAY_TEXT_CONFIG({
                .fontSize = 16,
                .fontId = FONT_ID_BODY_16,
                .textColor = base_theme.text
            })
        );

        CLAY({
            .layout = {
                .padding = CLAY_PADDING_ALL(16),
                .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
            },
            .backgroundColor = base_theme.background,
            .cornerRadius = CLAY_CORNER_RADIUS(4)
        }) {
            Clay_String habit_name = {
                .length = strlen(pending_delete_habit_name),
                .chars = pending_delete_habit_name
            };
            CLAY_TEXT(habit_name,
                CLAY_TEXT_CONFIG({
                    .fontSize = 18,
                    .fontId = FONT_ID_BODY_16,
                    .textColor = base_theme.text
                })
            );
        }

        CLAY({
            .layout = {
                .layoutDirection = CLAY_LEFT_TO_RIGHT,
                .childGap = 8,
                .childAlignment = { .x = CLAY_ALIGN_X_RIGHT }
            }
        }) {
            CLAY({
                .id = CLAY_ID("CancelButton"),
                .layout = {
                    .padding = CLAY_PADDING_ALL(8),
                    .sizing = { CLAY_SIZING_FIT(0), CLAY_SIZING_FIT(0) }
                },
                .backgroundColor = base_theme.background,
                .cornerRadius = CLAY_CORNER_RADIUS(4)
            }) {
                Clay_OnHover(HandleModalCancel, 0);
                CLAY_TEXT(CLAY_STRING("Cancel"),
                    CLAY_TEXT_CONFIG({
                        .fontSize = 16,
                        .fontId = FONT_ID_BODY_16,
                        .textColor = base_theme.text
                    })
                );
            }

            CLAY({
                .id = CLAY_ID("ConfirmButton"),
                .layout = {
                    .padding = CLAY_PADDING_ALL(8),
                    .sizing = { CLAY_SIZING_FIT(0), CLAY_SIZING_FIT(0) }
                },
                .backgroundColor = theme->danger,
                .cornerRadius = CLAY_CORNER_RADIUS(4)
            }) {
                Clay_OnHover(HandleModalConfirm, 0);
                CLAY_TEXT(CLAY_STRING("Delete"),
                    CLAY_TEXT_CONFIG({
                        .fontSize = 16,
                        .fontId = FONT_ID_BODY_16,
                        .textColor = base_theme.text
                    })
                );
            }
        }
    }
}
bool IsDeleteModalOpen(void) {
    return g_delete_habit_modal && g_delete_habit_modal->is_open;
}

void RenderDeleteHabitModal(void) {
    if (!g_delete_habit_modal) return;
    Rocks_RenderModal(g_delete_habit_modal);
}
