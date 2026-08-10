#!/bin/bash

# Build KeyboardCleaner as a proper macOS app bundle

APP_NAME="KeyboardCleaner"
APP_BUNDLE="$APP_NAME.app"
EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Clean up previous build
rm -rf "$APP_BUNDLE"

# Create app bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"

# Copy Info.plist
cp Info.plist "$APP_BUNDLE/Contents/"

# Compile the Swift code
echo "Compiling $APP_NAME..."
swiftc KeyboardCleaner.swift -o "$EXECUTABLE" \
    -framework Cocoa \
    -framework ApplicationServices \
    -framework Foundation

# Check if compilation succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "App bundle created at: $APP_BUNDLE"
    echo ""
    echo "To run:"
    echo "  open \"$APP_BUNDLE\""
    echo ""
    echo "Or move to Applications:"
    echo "  cp -r \"$APP_BUNDLE\" ~/Applications/"
    echo "  open ~/Applications/$APP_BUNDLE"
    echo ""
    echo "IMPORTANT: Grant Accessibility permissions in System Settings > Privacy & Security > Accessibility"
else
    echo ""
    echo "✗ Build failed!"
    echo ""
    echo "Make sure Xcode command line tools are installed:"
    echo "  xcode-select --install"
    exit 1
fi
