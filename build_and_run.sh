#!/bin/bash

# KeyboardCleaner - Build and Run Script
# This script compiles the KeyboardCleaner app

SOURCE_FILE="KeyboardCleaner.swift"
BUILD_DIR="./build"
APP_NAME="KeyboardCleaner"
OUTPUT_PATH="$BUILD_DIR/$APP_NAME"

# Create build directory
mkdir -p "$BUILD_DIR"

echo "Building $APP_NAME..."
echo "========================"
echo ""

# Compile with swiftc
swiftc "$SOURCE_FILE" -o "$OUTPUT_PATH" \
    -framework Cocoa \
    -framework ApplicationServices \
    -framework Foundation \
    -Xlinker -rpath \
    -Xlinker @executable_path/../Frameworks

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "Build successful!"
    echo ""
    echo "The app is located at: $OUTPUT_PATH"
    echo ""
    echo "To run the app:"
    echo "  open \"$OUTPUT_PATH\""
    echo ""
    echo "Or drag it to your Applications folder and launch from there."
    echo ""
    echo "IMPORTANT: You need to grant Accessibility permissions!"
    echo "  1. Launch the app"
    echo "  2. Go to System Settings > Privacy & Security > Accessibility"
    echo "  3. Add 'KeyboardCleaner' to the list and enable it"
else
    echo ""
    echo "Build failed!"
    echo ""
    echo "Make sure you have Xcode command line tools installed."
    echo "Run: xcode-select --install"
    echo ""
    exit 1
fi
