#ifndef HABIT_DELETE_MODAL_H
#define HABIT_DELETE_MODAL_H

#include "rocks.h"
#include "rocks_clay.h"
#include "habits_state.h"
#include "quest_theme.h"
#include "components/modal.h"

// Initialize/cleanup
void InitializeDeleteModal(void);
void CleanupDeleteModal(void);

// Rendering
void RenderDeleteModalContent(void);
void RenderDeleteHabitModal(void);

// Event handlers
void HandleDeleteButtonClick(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);
void HandleModalConfirm(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);
void HandleModalCancel(Clay_ElementId elementId, Clay_PointerData pointerInfo, intptr_t userData);

bool IsDeleteModalOpen(void);


#endif // HABIT_DELETE_MODAL_H