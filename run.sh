#!/usr/bin/env bash

# run.sh - Build kryon, compile main.kry, and run with raylib
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HABITS_DIR="$SCRIPT_DIR"
PROJECT_ROOT="$(dirname "$HABITS_DIR")"
KRYON_DIR="$PROJECT_ROOT/kryon"
BUILD_DIR="$KRYON_DIR/build"
BIN_DIR="$BUILD_DIR/bin"

print_status "Building and running Habits application..."
print_status "Habits directory: $HABITS_DIR"
print_status "Project root: $PROJECT_ROOT"

# Step 1: Build kryon
print_status "Step 1: Building kryon..."
if ! "$KRYON_DIR/scripts/build.sh"; then
    print_error "Failed to build kryon"
    exit 1
fi
print_success "Kryon build completed successfully"

# Check if kryon binary exists
KRYON_BIN="$BIN_DIR/kryon"
if [ ! -f "$KRYON_BIN" ]; then
    print_error "Kryon binary not found at $KRYON_BIN"
    exit 1
fi

# Step 2: Compile main.kry
MAIN_KRY="$HABITS_DIR/main.kry"
MAIN_KRB="$HABITS_DIR/main.krb"

print_status "Step 2: Compiling main.kry..."
if [ ! -f "$MAIN_KRY" ]; then
    print_error "main.kry not found at $MAIN_KRY"
    exit 1
fi

if ! "$KRYON_BIN" compile "$MAIN_KRY" -o "$MAIN_KRB"; then
    print_error "Failed to compile main.kry"
    exit 1
fi

print_success "Compilation completed successfully"

# Check if KRB file was created
if [ ! -f "$MAIN_KRB" ]; then
    print_error "KRB file was not created: $MAIN_KRB"
    exit 1
fi

# Step 3: Run with raylib renderer
print_status "Step 3: Running habits application with raylib renderer..."
if ! "$KRYON_BIN" run "$MAIN_KRB" --renderer raylib; then
    print_error "Failed to run habits application with raylib renderer"
    exit 1
fi

print_success "Habits application completed successfully!"