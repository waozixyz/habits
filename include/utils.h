#ifndef UTILS_H
#define UTILS_H

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include "config.h"

#if defined(CLAY_MOBILE)
#include <pthread.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <jni.h>

typedef struct {
    SDL_Window* window;
    AAssetManager* assetManager; 
    pthread_mutex_t mutex;
    bool initialized;
} AndroidState;

extern AndroidState g_android_state;

// JNI method declaration
extern JNIEXPORT void JNICALL 
Java_io_naox_quest_MainActivity_nativeSetAssetManager(
    JNIEnv* env, jclass clazz, jobject asset_manager);
#endif

float ScaleUI(float value);
int ScaleUIToInt(float value);
size_t strlcpy(char *dst, const char *src, size_t dstsize);
#endif // UTILS_H