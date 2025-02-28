#ifndef COLOR_PICKER_H
#define COLOR_PICKER_H

#include "rocks_clay.h"
#include "components/modal.h"
#include <stdio.h>
#include "config.h"

// Predefined color palette with 255.0f scale
static const Clay_Color COLOR_PALETTE[] = {
    {139.0f, 0.0f, 0.0f, 255.0f},      // Maroon
    {70.0f, 130.0f, 180.0f, 255.0f},   // Steel Blue
    {188.0f, 143.0f, 143.0f, 255.0f},  // Rosy Brown
    {218.0f, 112.0f, 214.0f, 255.0f},  // Orchid
    {102.0f, 205.0f, 170.0f, 255.0f},  // Medium Aquamarine
    {205.0f, 92.0f, 92.0f, 255.0f},    // Indian Red
    {255.0f, 140.0f, 0.0f, 255.0f},    // Dark Orange
    {123.0f, 104.0f, 238.0f, 255.0f},  // Medium Slate Blue
    {46.0f, 139.0f, 87.0f, 255.0f},    // Sea Green
    {255.0f, 20.0f, 147.0f, 255.0f},   // Deep Pink
    {160.0f, 82.0f, 45.0f, 255.0f},    // Sienna
    {0.0f, 191.0f, 255.0f, 255.0f},    // Deep Sky Blue
    // New colors
    {0.0f, 128.0f, 128.0f, 255.0f},    // Teal
    {255.0f, 127.0f, 80.0f, 255.0f},   // Coral
    {112.0f, 128.0f, 144.0f, 255.0f},  // Slate Gray
    {34.0f, 139.0f, 34.0f, 255.0f},    // Forest Green
    {128.0f, 0.0f, 128.0f, 255.0f},    // Purple
    {218.0f, 165.0f, 32.0f, 255.0f},   // Goldenrod
    {220.0f, 20.0f, 60.0f, 255.0f},    // Crimson
    {95.0f, 158.0f, 160.0f, 255.0f}    // Cadet Blue
};

#define COLOR_PALETTE_SIZE (sizeof(COLOR_PALETTE) / sizeof(Clay_Color))
#define COLORS_PER_ROW 4

// Function prototypes
void InitializeColorPicker(Clay_Color initial_color, void (*on_color_change)(Clay_Color));
void RenderColorPicker(Clay_Color current_color, void (*on_color_change)(Clay_Color));
void CleanupColorPicker(void);

#endif // COLOR_PICKER_H