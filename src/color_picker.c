#include "color_picker.h"  
#include "rocks.h"
#include "quest_theme.h"

static void (*g_color_change_callback)(Clay_Color) = NULL;
static Rocks_Modal* g_modal = NULL;
static Clay_Color g_current_color = {0};

static void HandleColorHover(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        size_t color_index = (size_t)userData;
        if (color_index < COLOR_PALETTE_SIZE && g_color_change_callback) {
            g_current_color = COLOR_PALETTE[color_index];
            g_color_change_callback(g_current_color);
            Rocks_CloseModal(g_modal);
        }
    }
}

static void HandleCurrentColorClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData) {
    if (pointerInfo.state == CLAY_POINTER_DATA_PRESSED_THIS_FRAME) {
        Rocks_OpenModal(g_modal);
    }
}

static void RenderColorOption(size_t index) {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    CLAY({
        .id = CLAY_IDI("ModalColorOption", index),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_FIXED(40),
                .height = CLAY_SIZING_FIXED(40)
            }
        },
        .backgroundColor = COLOR_PALETTE[index],
        .cornerRadius = CLAY_CORNER_RADIUS(4)
    }) {
        Clay_OnHover(HandleColorHover, (intptr_t)index);
    }
}

static void RenderColorRow(size_t start_index, size_t end_index) {
    CLAY({
        .id = CLAY_IDI("ColorGridRow", start_index),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_GROW(),
                .height = CLAY_SIZING_FIT()
            },
            .childGap = 10,
            .layoutDirection = CLAY_LEFT_TO_RIGHT,
            .childAlignment = { .x = CLAY_ALIGN_X_CENTER }
        }
    }) {
        for (size_t i = start_index; i < end_index; i++) {
            RenderColorOption(i);
        }
    }
}
static void RenderColorPaletteContent(void) {
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    CLAY({
        .id = CLAY_ID("ModalColorPalette"),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_GROW(),
                .height = CLAY_SIZING_FIT()
            },
            .childGap = 10,
            .layoutDirection = CLAY_TOP_TO_BOTTOM
        }
    }) {
        CLAY_TEXT(CLAY_STRING("Select a Color"), 
            CLAY_TEXT_CONFIG({
                .fontSize = 18,
                .fontId = FONT_ID_BODY_24,
                .textColor = base_theme.text
            })
        );

        CLAY({
            .id = CLAY_ID("ColorGrid"),
            .layout = {
                .sizing = {
                    .width = CLAY_SIZING_GROW(),
                    .height = CLAY_SIZING_FIT()
                },
                .childGap = 10,
                .layoutDirection = CLAY_TOP_TO_BOTTOM
            }
        }) {
            RenderColorRow(0, COLORS_PER_ROW);
            RenderColorRow(COLORS_PER_ROW, COLORS_PER_ROW * 2);
            RenderColorRow(COLORS_PER_ROW * 2, COLORS_PER_ROW * 3);
            RenderColorRow(COLORS_PER_ROW * 3, COLORS_PER_ROW * 4);
            RenderColorRow(COLORS_PER_ROW * 4, COLOR_PALETTE_SIZE);
        }
    }
}

void InitializeColorPicker(Clay_Color initial_color, void (*on_color_change)(Clay_Color)) {
    g_color_change_callback = on_color_change;
    g_current_color = initial_color;
    
    // Create modal with specific dimensions
    g_modal = Rocks_CreateModal(300, 400, RenderColorPaletteContent, NULL);
}

void RenderColorPicker(Clay_Color current_color, void (*on_color_change)(Clay_Color)) {
    if (!g_modal) {
        InitializeColorPicker(current_color, on_color_change);
    }

    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;

    CLAY({
        .id = CLAY_ID("ColorPickerContainer"),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_GROW(),
                .height = CLAY_SIZING_FIT()
            },
            .childGap = 10,
            .layoutDirection = CLAY_LEFT_TO_RIGHT,
            .padding = CLAY_PADDING_ALL(16)
        }
    }) {
        CLAY({
            .id = CLAY_ID("CurrentColorDisplay"),
            .layout = {
                .sizing = {
                    .width = CLAY_SIZING_FIXED(30),
                    .height = CLAY_SIZING_FIXED(30)
                }
            },
            .backgroundColor = current_color,
            .cornerRadius = CLAY_CORNER_RADIUS(8)
        }) {
            Clay_OnHover(HandleCurrentColorClick, 0);
        }
    }

    // Render the modal if it's open
    if (g_modal && g_modal->is_open) {
        Rocks_RenderModal(g_modal);
    }
}

void CleanupColorPicker(void) {
    if (g_modal) {
        Rocks_DestroyModal(g_modal);
        g_modal = NULL;
    }
}