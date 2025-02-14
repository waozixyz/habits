#define ROCKS_CLAY_IMPLEMENTATION
#include "rocks.h"
#include "rocks_clay.h"
#include <stdio.h>
#include "quest_theme.h"
#include "config.h"
#include "habits.h"
#include "utils.h"

// Font loading configuration
typedef struct {
    const char* path;
    int size;
    uint32_t id;
} FontConfig;

static const FontConfig FONT_CONFIGS[] = {
    {"fonts/Calistoga-Regular.ttf", 16, FONT_ID_BODY_16},
    {"fonts/Quicksand-Semibold.ttf", 56, FONT_ID_TITLE_56},
    {"fonts/Calistoga-Regular.ttf", 24, FONT_ID_BODY_24},
    {"fonts/Calistoga-Regular.ttf", 36, FONT_ID_BODY_36},
    {"fonts/Quicksand-Semibold.ttf", 36, FONT_ID_TITLE_36},
    {"fonts/Quicksand-Semibold.ttf", 24, FONT_ID_MONOSPACE_24},
    {"fonts/Calistoga-Regular.ttf", 14, FONT_ID_BODY_14},
    {"fonts/Calistoga-Regular.ttf", 18, FONT_ID_BODY_18}
};
#define FONT_CONFIG_COUNT (sizeof(FONT_CONFIGS) / sizeof(FONT_CONFIGS[0]))

static bool LoadFonts(void) {
    printf("DEBUG: Starting to load fonts...\n");
    
    bool success = true;
    uint16_t font_id;
    for (size_t i = 0; i < FONT_CONFIG_COUNT; i++) {
        font_id = Rocks_LoadFont(FONT_CONFIGS[i].path, FONT_CONFIGS[i].size, FONT_CONFIGS[i].id);
        if (font_id == UINT16_MAX) {
            printf("ERROR: Failed to load font: %s (size: %d)\n", 
                   FONT_CONFIGS[i].path, FONT_CONFIGS[i].size);
            success = false;
            break;
        }
        printf("DEBUG: Successfully loaded font %s (size: %d, id: %u)\n",
               FONT_CONFIGS[i].path, FONT_CONFIGS[i].size, font_id);
    }
    if (!success) {
        // Cleanup any fonts that were loaded
        for (uint16_t i = 0; i < FONT_CONFIG_COUNT; i++) {
            Rocks_UnloadFont(i);
        }
        return false;
    }
    printf("DEBUG: Successfully loaded all fonts\n");
    return true;
}

static Clay_RenderCommandArray update(Rocks* rocks, float dt) {
    Rocks_Theme theme = Rocks_GetTheme(rocks);

    Clay_BeginLayout();
    CLAY({
        .id = CLAY_ID("MainContainer"),
        .layout = {
            .sizing = { CLAY_SIZING_GROW(), CLAY_SIZING_GROW() },
            .childAlignment = { CLAY_ALIGN_X_CENTER, CLAY_ALIGN_Y_CENTER },
            .layoutDirection = CLAY_TOP_TO_BOTTOM,
            .childGap = 20
        },
        .backgroundColor = theme.background
    }) {
        RenderHabitsPage(dt);
    }
    return Clay_EndLayout();
}

int main(void) {
    printf("DEBUG: Program starting...\n");

    // Create the Quest theme and configure Rocks
    QuestTheme theme;
    
    Rocks_Config config = {
        .window_width = 800,
        .window_height = 600,
        .window_title = "Habits",
        .arena_size = 1024 * 1024 * 64
    };

    // Create and assign theme
    theme = quest_theme_create();
    config.theme = theme.base;

    // Initialize Rocks
    printf("DEBUG: Initializing Rocks...\n");

    const int MAX_ELEMENTS = 16384; 
    Clay_SetMaxElementCount(MAX_ELEMENTS);

    Rocks* rocks = Rocks_Init(config);
    if (!rocks) {
        printf("ERROR: Failed to initialize Rocks\n");
        quest_theme_destroy(&theme);
        return 1;
    }
    printf("DEBUG: Rocks initialized successfully\n");

    // Load fonts
    if (!LoadFonts()) {
        printf("ERROR: Font loading failed\n");
        quest_theme_destroy(&theme);
        Rocks_Cleanup(rocks);
        return 1;
    }
    printf("DEBUG: Fonts loaded successfully\n");

    // Initialize habits page
    printf("DEBUG: Initializing habits page...\n");
    InitializeHabitsPage(rocks);
    printf("DEBUG: Habits page initialized successfully\n");

    // Run the main loop
    printf("DEBUG: Starting main loop...\n");
    Rocks_Run(rocks, update);
    printf("DEBUG: Main loop ended\n");

    // Cleanup
    printf("DEBUG: Starting cleanup...\n");
    CleanupHabitsPage(rocks);
    quest_theme_destroy(&theme);
    Rocks_Cleanup(rocks);
    printf("DEBUG: Cleanup completed\n");
    printf("DEBUG: Program ending normally\n");

    return 0;
}