# Makefile
CC = gcc
CCACHE = ccache
MKDIR = mkdir -p
CP = cp -r
RM = rm -rf

# Directories
BUILD_DIR = build
SRC_DIR = src
ROCKS_DIR = lib/rocks
ASSETS_DIR = assets
CLAY_DIR = lib/rocks/clay
CJSON_DIR = lib/cJSON
VENDOR_DIR = lib/rocks/vendor
NANOSVG_DIR = $(VENDOR_DIR)/nanosvg/src

# Flags
CFLAGS = -Wall -Werror -O2 \
         -Wno-unused-variable \
         -Wno-missing-braces \
         -Wno-unused-but-set-variable \
         -DROCKS_USE_RAYLIB \
         -DCLAY_DESKTOP

INCLUDE_FLAGS = -I./include \
                -I$(ROCKS_DIR)/include \
                -I$(ROCKS_DIR)/include/renderer \
                -I$(ROCKS_DIR)/ineclude/components \
                -I$(CLAY_DIR) \
                -I$(NANOSVG_DIR) \
                -I$(CJSON_DIR)

# Get Raylib flags
RAYLIB_FLAGS := $(shell pkg-config --cflags raylib)
RAYLIB_LIBS := $(shell pkg-config --libs raylib)

# Source files
SRC_FILES = $(wildcard $(SRC_DIR)/*.c) \
            $(wildcard $(SRC_DIR)/*/*.c) \
            $(wildcard $(SRC_DIR)/*/*/*.c) \
            $(wildcard $(ROCKS_DIR)/src/*.c) \
            $(wildcard $(ROCKS_DIR)/src/components/*.c) \
            $(wildcard $(ROCKS_DIR)/src/renderer/raylib_*.c) \
            $(CJSON_DIR)/cJSON.c

# Object files
OBJ_FILES = $(patsubst %.c,$(BUILD_DIR)/%.o,$(notdir $(SRC_FILES)))

# Main target
all: prepare $(BUILD_DIR)/habits copy_assets

# Prepare build directory
prepare:
	$(MKDIR) $(BUILD_DIR)
	$(MKDIR) $(BUILD_DIR)/assets

# Compile source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CCACHE) $(CC) -c $< -o $@ $(CFLAGS) $(RAYLIB_FLAGS) $(INCLUDE_FLAGS)

$(BUILD_DIR)/%.o: $(ROCKS_DIR)/src/%.c
	$(CCACHE) $(CC) -c $< -o $@ $(CFLAGS) $(RAYLIB_FLAGS) $(INCLUDE_FLAGS)

$(BUILD_DIR)/%.o: $(ROCKS_DIR)/src/components/%.c
	$(CCACHE) $(CC) -c $< -o $@ $(CFLAGS) $(RAYLIB_FLAGS) $(INCLUDE_FLAGS)

$(BUILD_DIR)/%.o: $(ROCKS_DIR)/src/renderer/%.c
	$(CCACHE) $(CC) -c $< -o $@ $(CFLAGS) $(RAYLIB_FLAGS) $(INCLUDE_FLAGS)

$(BUILD_DIR)/%.o: $(CJSON_DIR)/%.c
	$(CCACHE) $(CC) -c $< -o $@ $(CFLAGS) $(INCLUDE_FLAGS)

# Link
$(BUILD_DIR)/habits: $(OBJ_FILES)
	$(CC) $^ -o $@ $(RAYLIB_FLAGS) $(RAYLIB_LIBS) -lm -ldl -lpthread -lsodium

# Copy assets
copy_assets:
	@if [ -d "$(ASSETS_DIR)" ]; then \
		$(CP) $(ASSETS_DIR)/* $(BUILD_DIR)/assets/; \
	fi

# Clean
clean:
	$(RM) $(BUILD_DIR)
	@echo "Clean completed successfully!"

.PHONY: all prepare copy_assets clean