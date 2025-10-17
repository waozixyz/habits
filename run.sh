#!/usr/bin/env bash

# run.sh - Compile and run the Nim-based Habits app
# Usage: ./run.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HABITS_DIR="$SCRIPT_DIR"

print_status "Running Habits application (Nim version)..."
print_status "Habits directory: $HABITS_DIR"

# Compile and run with Nim
MAIN_FILE="$HABITS_DIR/main.nim"

if [ ! -f "$MAIN_FILE" ]; then
    print_error "main.nim not found at $MAIN_FILE"
    exit 1
fi

print_status "Running habits app with Kryon..."
cd "$HABITS_DIR"
kryon run --filename main.nim

print_success "Habits application completed!"