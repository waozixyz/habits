#ifndef CALENDAR_BOX_H
#define CALENDAR_BOX_H

#include <stdbool.h>
#include "rocks_clay.h"
#include <stdio.h>
#include <math.h>

typedef struct {
    int day_number;
    bool is_today;
    bool is_past;
    bool is_completed;
    void (*on_click)(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);
    Clay_Color custom_color;
    time_t date; 
} CalendarBoxProps;

void RenderCalendarBox(CalendarBoxProps props);

#endif