#include "quest_theme.h"
#include <stdlib.h>

QuestTheme quest_theme_create(void) {
    QuestThemeExtension* ext = malloc(sizeof(QuestThemeExtension));
    *ext = (QuestThemeExtension){
        .nav_background = (Clay_Color){45, 31, 51, 255},      // #2d1f33
        .nav_item_background = (Clay_Color){45, 31, 51, 0},   // transparent
        .nav_item_active = (Clay_Color){74, 38, 57, 255},     // #4a2639
        .nav_text = (Clay_Color){230, 221, 233, 255},         // #e6dde9
        .nav_text_active = (Clay_Color){255, 107, 151, 255},  // #ff6b97
        .nav_shadow = (Clay_Color){0, 0, 0, 50},              // semi-transparent black
        .card = (Clay_Color){45, 31, 51, 255},               // #2d1f33
        .card_hover = (Clay_Color){61, 42, 66, 255},         // #3d2a42
        .accent = (Clay_Color){255, 107, 151, 255},          // #ff6b97
        .accent_hover = (Clay_Color){255, 127, 171, 255},    // lighter accent
        .border = (Clay_Color){74, 38, 57, 255},            // #4a2639
        .border_focused = (Clay_Color){148, 47, 74, 255},    // #942f4a
        .error_hover = (Clay_Color){255, 87, 74, 255},       // #ff574a
        .cursor = (Clay_Color){255, 107, 151, 255},          // #ff6b97
        .danger = (Clay_Color){255, 99, 71, 255},             // #ff6347
        .success = (Clay_Color){76, 175, 80, 255}            // #4CAF50
    };

    return (QuestTheme){
        .base = {
            .background = (Clay_Color){26, 15, 31, 255},        // #1a0f1f
            .background_hover = (Clay_Color){45, 26, 44, 255},  // #2d1a2c
            .background_focused = (Clay_Color){35, 20, 40, 255}, // #231428
            .primary = (Clay_Color){148, 47, 74, 255},          // #942f4a
            .primary_hover = (Clay_Color){177, 54, 88, 255},    // #b13658
            .primary_focused = (Clay_Color){187, 64, 98, 255},  // #bb4062
            .secondary = (Clay_Color){74, 38, 57, 255},         // #4a2639
            .secondary_hover = (Clay_Color){84, 48, 67, 255},   // #543043
            .secondary_focused = (Clay_Color){94, 58, 77, 255}, // #5e3a4d
            .text = (Clay_Color){230, 221, 233, 255},          // #e6dde9
            .text_secondary = (Clay_Color){184, 168, 192, 255}, // #b8a8c0
            .scrollbar_track = (Clay_Color){45, 31, 51, 200},   // #2d1f33c8
            .scrollbar_thumb = (Clay_Color){74, 38, 57, 255},   // #4a2639
            .scrollbar_thumb_hover = (Clay_Color){148, 47, 74, 255}, // #942f4a
            .extension = ext
        },
        .extension = ext
    };
}

void quest_theme_destroy(QuestTheme* theme) {
    if (theme->extension) {
        free(theme->extension);
        theme->base.extension = NULL;
        theme->extension = NULL;
    }
}