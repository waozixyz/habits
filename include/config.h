#ifndef CONFIG_H
#define CONFIG_H

#include "rocks_clay.h"
#include <stdio.h>

// Window & UI configuration
extern double windowWidth, windowHeight;
extern float globalScalingFactor;

// Breakpoints
extern const float BREAKPOINT_LARGE;
extern const float BREAKPOINT_MEDIUM;
extern const float BREAKPOINT_SMALL;
extern const float BREAKPOINT_XSMALL;
// Font IDs
#define FONT_ID_BODY_16 0
#define FONT_ID_TITLE_56 1
#define FONT_ID_BODY_24 2
#define FONT_ID_BODY_36 3
#define FONT_ID_TITLE_36 4
#define FONT_ID_MONOSPACE_24 5
#define FONT_ID_BODY_14 6
#define FONT_ID_BODY_18 7

typedef struct {
    float delta_time;
    bool isTextInput;
    char text[32];
    int key;
} InputEvent;

#endif