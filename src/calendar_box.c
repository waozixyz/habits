#include "calendar_box.h"
#include "config.h"
#include "rocks.h"
#include "quest_theme.h"

static const Clay_String DAY_STRINGS[32] = {
    CLAY_STRING_CONST("0"), CLAY_STRING_CONST("1"), CLAY_STRING_CONST("2"), CLAY_STRING_CONST("3"), CLAY_STRING_CONST("4"), 
    CLAY_STRING_CONST("5"), CLAY_STRING_CONST("6"), CLAY_STRING_CONST("7"), CLAY_STRING_CONST("8"), CLAY_STRING_CONST("9"),
    CLAY_STRING_CONST("10"), CLAY_STRING_CONST("11"), CLAY_STRING_CONST("12"), CLAY_STRING_CONST("13"), CLAY_STRING_CONST("14"),
    CLAY_STRING_CONST("15"), CLAY_STRING_CONST("16"), CLAY_STRING_CONST("17"), CLAY_STRING_CONST("18"), CLAY_STRING_CONST("19"),
    CLAY_STRING_CONST("20"), CLAY_STRING_CONST("21"), CLAY_STRING_CONST("22"), CLAY_STRING_CONST("23"), CLAY_STRING_CONST("24"),
    CLAY_STRING_CONST("25"), CLAY_STRING_CONST("26"), CLAY_STRING_CONST("27"), CLAY_STRING_CONST("28"), CLAY_STRING_CONST("29"),
    CLAY_STRING_CONST("30"), CLAY_STRING_CONST("31")
};

static Clay_Color ClampColor(Clay_Color color) {
    return (Clay_Color){
        .r = fminf(fmaxf(color.r / 255.0f, 0.0f), 1.0f) * 255.0f,
        .g = fminf(fmaxf(color.g / 255.0f, 0.0f), 1.0f) * 255.0f,
        .b = fminf(fmaxf(color.b / 255.0f, 0.0f), 1.0f) * 255.0f,
        .a = fminf(fmaxf(color.a / 255.0f, 0.0f), 1.0f) * 255.0f
    };
}

static Clay_Color GenerateHoverColor(Clay_Color color) {
    return ClampColor((Clay_Color){
        .r = fminf(color.r * 1.3f, 255.0f),
        .g = fminf(color.g * 1.3f, 255.0f),
        .b = fminf(color.b * 1.3f, 255.0f),
        .a = color.a
    });
}

static Clay_Color GeneratePastColor(Clay_Color color) {
    return ClampColor((Clay_Color){
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a
    });
}

static Clay_Color GenerateCompletedColor(Clay_Color color) {
    return ClampColor((Clay_Color){
        .r = color.r * 1.1f,
        .g = color.g * 1.1f,
        .b = color.b * 1.1f,
        .a = 200
    });
}

static Clay_Color GenerateFutureColor(Clay_Color color) {
    return ClampColor((Clay_Color){
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a
    });
}

void RenderCalendarBox(CalendarBoxProps props) {    
    if (props.day_number < 0 || props.day_number > 31) {
        printf("Error: Invalid day number %d\n", props.day_number);
        return;
    }
    if (!GRocks) {
        printf("Error: GRocks is null\n");
        return;
    }
    
    Rocks_Theme base_theme = Rocks_GetTheme(GRocks);
    if (!base_theme.extension) {
        printf("Error: Theme extension is null\n");
        return;
    }
    QuestThemeExtension* theme = (QuestThemeExtension*)base_theme.extension;
    if (!theme) {
        printf("Error: Theme is null\n");
        return;
    }
    
    if (windowWidth <= 0) {
        printf("Error: Invalid window width\n");
        return;
    }
    float screenWidth = (float)windowWidth;
    
    const float MAX_BOX_SIZE = 90.0f;
    const float MIN_BOX_SIZE = 32.0f;
    float boxSize = screenWidth * 0.1f;
    boxSize = fmaxf(MIN_BOX_SIZE, fminf(boxSize, MAX_BOX_SIZE));

    if (props.day_number >= sizeof(DAY_STRINGS)/sizeof(DAY_STRINGS[0])) {
        printf("Error: Day number %d exceeds DAY_STRINGS array bounds\n", props.day_number);
        return;
    }

    Clay_Color base_color = props.custom_color;
    base_color.a = 70.0f;
    Clay_Color box_color = base_color;
    Clay_Color hover_color = base_color;
    
    if (props.is_past) {
        box_color = GeneratePastColor(base_color);
        hover_color = GenerateHoverColor(box_color);
    } else if (!props.is_past && !props.is_today) {
        box_color = GenerateFutureColor(base_color);
        hover_color = GenerateHoverColor(base_color);
    }

    if (props.is_completed) {
        box_color = GenerateCompletedColor(base_color);
        hover_color = GenerateHoverColor(box_color);
    }

    Clay_Color today_border_color = theme->accent;
    int fontSize = (int)(boxSize * 0.25f);

    CLAY({
        .id = CLAY_IDI("Box", props.unique_index),
        .layout = {
            .sizing = {
                .width = CLAY_SIZING_FIXED(boxSize),
                .height = CLAY_SIZING_FIXED(boxSize)
            },
            .childAlignment = {
                .x = CLAY_ALIGN_X_CENTER,
                .y = CLAY_ALIGN_Y_CENTER
            }
        },
        .backgroundColor = Clay_Hovered() ? hover_color : box_color,
        .border = props.is_today ? (Clay_BorderElementConfig){
            .color = today_border_color,
            .width = CLAY_BORDER_ALL(2)
        } : (Clay_BorderElementConfig){0},
        .cornerRadius = CLAY_CORNER_RADIUS(8)
    }) {
        if ((props.is_past || props.is_today) && props.on_click != NULL) {
            Clay_OnHover(props.on_click, props.unique_index);
        }
        
        if (props.day_number >= 0 && props.day_number < sizeof(DAY_STRINGS)/sizeof(DAY_STRINGS[0])) {
            CLAY_TEXT(DAY_STRINGS[props.day_number], 
                CLAY_TEXT_CONFIG({ 
                    .fontSize = fontSize,
                    .fontId = FONT_ID_BODY_16,
                    .textColor = base_theme.text
                })
            );
        }
    }
}