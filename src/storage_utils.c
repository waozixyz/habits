#include "storage_utils.h"
#include <utils.h>
#include <assert.h>

#ifndef __EMSCRIPTEN__

// Constants
#define DIRECTORY_PERMISSIONS 0755

// Helper function to construct file paths safely
static int construct_file_path(char* dest, size_t dest_size, const char* root_dir, const char* filename) {
    int result = snprintf(dest, dest_size, "%s/%s", root_dir, filename);
    if (result < 0 || result >= dest_size) {
        printf("Error: Path too long: %s/%s\n", root_dir, filename);
        return -1;
    }
    return 0;
}

int ensure_directory_exists(const char* path) {
    assert(path != NULL);

    struct stat st = {0};
    char tmp[MAX_PATH_LENGTH];
    char *p = NULL;
    size_t len;

    // Copy the path to a temporary buffer
    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);

    // Remove trailing slash if present
    if (tmp[len - 1] == '/')
        tmp[len - 1] = 0;

    // Attempt to create the full directory path
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;  // Temporarily truncate the path
            
            // Try to create the parent directory
            if (stat(tmp, &st) == -1) {
                int mkdir_result = mkdir(tmp, DIRECTORY_PERMISSIONS);
                if (mkdir_result != 0 && errno != EEXIST) {
                    printf("Error: Failed to create directory: %s. Error: %s\n", 
                        tmp, strerror(errno));
                    return -1;
                }
            }

            *p = '/';  // Restore the path separator
        }
    }

    // Create the final directory
    if (stat(tmp, &st) == -1) {
        int mkdir_result = mkdir(tmp, DIRECTORY_PERMISSIONS);
        if (mkdir_result != 0 && errno != EEXIST) {
            printf("Error: Failed to create final directory: %s. Error: %s\n", 
                tmp, strerror(errno));
            return -1;
        }
    }

    return 0;
}

void determine_storage_directory(StorageConfig* config) {
    assert(config != NULL);
    memset(config, 0, sizeof(StorageConfig));

#if defined(CLAY_MOBILE)
    // Android-specific storage paths
    const char* potential_paths[] = {
        "/data/data/" APP_PACKAGE "/files",
        "/data/user/0/" APP_PACKAGE "/files",
        "/storage/emulated/0/Android/data/" APP_PACKAGE "/files"
    };

    for (int i = 0; i < 3; i++) {
        if (ensure_directory_exists(potential_paths[i]) == 0) {
            strlcpy(config->root_dir, potential_paths[i], MAX_PATH_LENGTH);
            break;
        }
    }

    if (strlen(config->root_dir) == 0) {
        // Fallback
        strcpy(config->root_dir, "/data/data/" APP_PACKAGE "/files");
        ensure_directory_exists(config->root_dir);
    }

#else
    // Desktop platforms - prefer Documents folder
    const char* home_dir = getenv("HOME");
    char full_path[MAX_PATH_LENGTH];

    if (home_dir) {
        // Try Documents/quest first
        snprintf(full_path, sizeof(full_path), "%s/Documents/quest", home_dir);
        
        if (ensure_directory_exists(full_path) == 0) {
            strlcpy(config->root_dir, full_path, MAX_PATH_LENGTH);
        } else {
            // Fallback to XDG paths
            const char* xdg_data_home = getenv("XDG_DATA_HOME");
            
            if (xdg_data_home) {
                snprintf(full_path, sizeof(full_path), "%s/quest", xdg_data_home);
            } else {
                snprintf(full_path, sizeof(full_path), "%s/.local/share/quest", home_dir);
            }

            if (ensure_directory_exists(full_path) == 0) {
                strlcpy(config->root_dir, full_path, MAX_PATH_LENGTH);
            } else {
                printf("Warning: Failed to create quest directory. Falling back to current directory.\n");
                strcpy(config->root_dir, ".");
            }
        }
    } else {
        // Absolute last resort: current directory
        printf("Warning: Could not determine home directory. Using current directory.\n");
        strcpy(config->root_dir, ".");
    }
#endif

    // Construct specific file paths with error handling
    if (construct_file_path(config->habits_path, MAX_PATH_LENGTH, config->root_dir, "habits.json") != 0 ||
        construct_file_path(config->todos_path, MAX_PATH_LENGTH, config->root_dir, "todos.json") != 0) {
        printf("Error: Storage path too long. Using default filenames.\n");
        strcpy(config->habits_path, "habits.json");
        strcpy(config->todos_path, "todos.json");
    }
}

int write_file_contents(const char* path, const char* contents, size_t length) {
    assert(path != NULL && contents != NULL);

    FILE* file = fopen(path, "wb");
    if (!file) {
        printf("Error: Could not open file for writing: %s\n", path);
        return -1;
    }

    size_t written = fwrite(contents, 1, length, file);
    fclose(file);

    if (written != length) {
        printf("Error: Failed to write entire file: %s\n", path);
        return -1;
    }

    return 0;
}

char* read_file_contents(const char* path, long* file_size) {
    assert(path != NULL && file_size != NULL);

    FILE* file = fopen(path, "rb");
    if (!file) {
        printf("Warning: Could not open file for reading: %s\n", path);
        return NULL;
    }

    // Get file size
    fseek(file, 0, SEEK_END);
    *file_size = ftell(file);
    rewind(file);

    // Allocate memory
    char* buffer = malloc(*file_size + 1);
    if (!buffer) {
        fclose(file);
        printf("Error: Failed to allocate memory for file reading\n");
        return NULL;
    }

    // Read file contents
    size_t read_size = fread(buffer, 1, *file_size, file);
    fclose(file);

    if (read_size != *file_size) {
        printf("Error: Failed to read entire file: %s\n", path);
        free(buffer);
        return NULL;
    }

    buffer[*file_size] = '\0';  // Null-terminate
    return buffer;
}
#endif