<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-dark.png">
    <img src="assets/logo-light.png" alt="KeyboardCleaner" width="480">
  </picture>
</p>

<p align="center">
  <a href="https://github.com/mkupermann/mackeyboardcleaner/actions/workflows/build.yml"><img src="https://github.com/mkupermann/mackeyboardcleaner/actions/workflows/build.yml/badge.svg" alt="Build status"></a>
</p>

A macOS menu bar app that temporarily disables all keyboard input, so you can clean your MacBook keyboard without triggering keystrokes.

Click the keyboard symbol in the menu bar to block input, click the lock to release it. Blocking is system-wide, and the keyboard is automatically re-enabled when the app quits. As a safety net, blocking auto-unlocks after 5 minutes (a countdown is shown next to the lock; can be turned off in the menu).

Also works on cats: paws on the keyboard are ignored like any other keystroke.

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode command line tools (for building)

## Installation

Build the app bundle and launch it:

```bash
git clone https://github.com/mkupermann/mackeyboardcleaner.git
cd mackeyboardcleaner
./build_app.sh
open KeyboardCleaner.app
```

To keep it around, move it to your Applications folder first:

```bash
cp -r KeyboardCleaner.app ~/Applications/
open ~/Applications/KeyboardCleaner.app
```

For a quick test without an app bundle you can compile the single source file directly (`./build_and_run.sh` or plain `swiftc`), but the bundle build above is the intended way to run it — it carries the app icon and menu-bar-only behavior.

## Usage

1. Launch the app — a keyboard symbol appears in your menu bar
2. Grant Accessibility permission when prompted (System Settings > Privacy & Security > Accessibility — add KeyboardCleaner and enable it). Without this permission, blocking cannot work.
3. Click the keyboard symbol to block input — the icon changes to a lock with a countdown
4. Clean your keyboard — keystrokes have no effect
5. Click the lock to re-enable the keyboard (or wait for the 5-minute auto-unlock)

Right-click (or Ctrl-click) the icon for the menu: block/stop blocking, toggle the auto-unlock timer, About, and Quit.

## How It Works

The app uses macOS's CGEventTap API to intercept and discard keyboard events (key down, key up, and modifier flag changes) before they reach any application. While blocking is active, all keyboard input is invisible to the system — in every application. Quitting the app removes the event tap and restores normal input.

## Troubleshooting

### Icon not visible in the menu bar

On MacBooks with a notch, macOS hides menu bar items that don't fit next to the notch. If your menu bar is crowded, quit another menu bar app to free a slot — the keyboard symbol will slide into view.

### Keyboard still responds when blocked

Accessibility permission isn't properly granted. Check:

1. KeyboardCleaner appears in System Settings > Privacy & Security > Accessibility and is enabled
2. If it was already listed, remove it, restart the app, and grant the permission again
3. Keep the app in your Applications folder or another stable location — moving or rebuilding the app invalidates the granted permission

### Build fails

Install the Xcode command line tools:

```bash
xcode-select --install
```

## For cat owners

Paws are treated as noise.

## Alternatives

This is a small, single-file utility I wrote because I wanted my own minimal version. If you prefer an established tool: [KeyboardCleanTool](https://folivora.ai/keyboardcleantool) (by the BetterTouchTool developer) or [keyboard-cleaner](https://github.com/gltchitm/keyboard-cleaner) cover the same use case.

## License

[MIT](LICENSE)
