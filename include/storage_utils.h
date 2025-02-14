#ifndef STORAGE_UTILS_H
#define STORAGE_UTILS_H
#ifndef __EMSCRIPTEN__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <string.h>

#define MAX_PATH_LENGTH 1024
#define APP_PACKAGE "io.naox.quest"

// Storage configuration structure
typedef struct {
    char root_dir[MAX_PATH_LENGTH];     // Base directory for storage
    char habits_path[MAX_PATH_LENGTH];  // Full path to habits JSON
    char todos_path[MAX_PATH_LENGTH];   // Full path to todos JSON
} StorageConfig;

// Platform-independent directory creation
int ensure_directory_exists(const char* path);

// Determine appropriate storage directory based on platform
void determine_storage_directory(StorageConfig* config);

int write_file_contents(const char* path, const char* contents, size_t length);
char* read_file_contents(const char* path, long* file_size);

// Path retrieval functions
const char* get_habits_file_path(StorageConfig* config);
const char* get_todos_file_path(StorageConfig* config);

#endif
#endif // STORAGE_UTILS_H