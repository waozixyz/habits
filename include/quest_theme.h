#ifndef QUEST_THEME_H
#define QUEST_THEME_H

#include "rocks.h"

typedef struct {
    Clay_Color nav_background;
    Clay_Color nav_item_background;
    Clay_Color nav_item_active;
    Clay_Color nav_text;
    Clay_Color nav_text_active;
    Clay_Color nav_shadow;
    Clay_Color card;
    Clay_Color card_hover;
    Clay_Color accent;
    Clay_Color accent_hover;
    Clay_Color border;
    Clay_Color border_focused;
    Clay_Color error_hover;
    Clay_Color cursor;
    Clay_Color danger;
    Clay_Color success;
} QuestThemeExtension;

typedef struct {
    Rocks_Theme base;
    QuestThemeExtension* extension;
} QuestTheme;

QuestTheme quest_theme_create(void);
void quest_theme_destroy(QuestTheme* theme);

#endif
