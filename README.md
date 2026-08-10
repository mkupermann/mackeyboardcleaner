# KeyboardCleaner

A simple macOS menu bar app that allows you to temporarily disable all keyboard input, making it easy to clean your MacBook keyboard without triggering unwanted actions.

## Features

- **Menu Bar App**: Runs quietly in your menu bar
- **One-Click Toggle**: Click the menu bar icon to enable/disable keyboard blocking
- **Visual Feedback**: Icon changes from 🧹 (enabled) to 🔒 (blocked)
- **Auto-Enable on Quit**: Keyboard is automatically re-enabled when you quit the app
- **Accessibility Integration**: Guides you through granting necessary permissions

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode command line tools (for building)

## Installation

### Option 1: Build from Source

1. **Clone or download** this repository
2. **Open Terminal** and navigate to the project directory:
   ```bash
   cd /path/to/KeyboardCleaner
   ```
3. **Make the build script executable**:
   ```bash
   chmod +x build_and_run.sh
   ```
4. **Build and run**:
   ```bash
   ./build_and_run.sh
   ```

### Option 2: Compile Directly with Swift

```bash
swiftc KeyboardCleaner.swift -o KeyboardCleaner \
    -framework Cocoa \
    -framework ApplicationServices \
    -framework Foundation
```

Then run:
```bash
./KeyboardCleaner
```

## Usage

1. **Launch the app** - It will appear as a broom icon (🧹) in your menu bar
2. **Grant Accessibility Permissions** - The app will guide you to enable it in:
   - System Settings > Privacy & Security > Accessibility
   - Add "KeyboardCleaner" to the list and enable it
3. **Click the menu bar icon** to toggle keyboard blocking:
   - 🧹 = Keyboard is **enabled** (normal operation)
   - 🔒 = Keyboard is **blocked** (cleaning mode)
4. **Clean your keyboard** - Press any keys, they will have no effect
5. **Click again** to re-enable your keyboard

## Important Notes

- The app **requires Accessibility permissions** to block keyboard input
- Without these permissions, keyboard blocking will not work
- The app will prompt you to enable permissions when first launched
- Keyboard blocking is **system-wide** - it affects all applications
- The app automatically re-enables your keyboard when quit

## How It Works

The app uses macOS's CGEventTap API to intercept and discard keyboard events (key down, key up, and modifier flags changes) before they reach any application. This effectively makes all keyboard input invisible to the system while the blocking is active.

## Troubleshooting

### Accessibility Permissions Not Working

1. Quit the app completely
2. Go to System Settings > Privacy & Security > Accessibility
3. Remove "KeyboardCleaner" from the list
4. Restart the app and grant permissions again
5. Make sure the app is in your Applications folder or a trusted location

### App Crashes on Launch

Make sure you have Xcode command line tools installed:
```bash
xcode-select --install
```

### Keyboard Still Responds When Blocked

This usually means Accessibility permissions aren't properly granted. Check:
1. The app appears in System Settings > Privacy & Security > Accessibility
2. The checkbox next to it is checked
3. Try restarting your Mac after granting permissions

## Alternatives

This is a small, single-file utility I wrote because I wanted my own minimal version. If you prefer an established tool: [KeyboardCleanTool](https://folivora.ai/keyboardcleantool) (by the BetterTouchTool developer) or [keyboard-cleaner](https://github.com/gltchitm/keyboard-cleaner) cover the same use case.

## License

[MIT](LICENSE)
