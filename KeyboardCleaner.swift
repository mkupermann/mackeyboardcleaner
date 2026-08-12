import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isKeyboardBlocked: Bool = false
    private var autoUnlockTimer: Timer?
    private var remainingSeconds: Int = 0

    private static let autoUnlockKey = "autoUnlockEnabled"
    private static let autoUnlockSeconds = 300

    // NX_SYSDEFINED from IOLLEvent.h - CGEventType has no case for it.
    // The F-row special functions (brightness/volume/media/backlight) arrive
    // as this type with subtype 8; the key code sits in data1, bits 16-31.
    fileprivate static let nxSysDefined: UInt32 = 14
    private static let nxSubtypeAuxControlButtons: Int16 = 8
    private static let nxKeyTypePower: Int = 6

    // Decision rule for NX_SYSDEFINED events while blocking, kept free of
    // event plumbing so it stays testable without TCC grants.
    fileprivate static func shouldSwallowSysDefined(subtype: Int16, auxKeyCode: Int) -> Bool {
        // Subtype 7 (aux mouse buttons), screen-changed, sticky-keys: pass -
        // the mouse is the only way out of blocking.
        guard subtype == nxSubtypeAuxControlButtons else { return false }
        // Never swallow the power key - second emergency exit.
        return auxKeyCode != nxKeyTypePower
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: [Self.autoUnlockKey: true])
        terminateIfAlreadyRunning()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeft
        }

        updateStatusItem()

        DispatchQueue.main.async {
            self.requestAccessibilityPermissions()
        }

        print("KeyboardCleaner launched - look for the keyboard icon in your menu bar")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Ensure keyboard is re-enabled when app quits
        stopBlocking()
        print("KeyboardCleaner terminating - keyboard re-enabled")
    }

    // A second instance would add a second (possibly notch-hidden) status item
    private func terminateIfAlreadyRunning() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        if !others.isEmpty {
            print("KeyboardCleaner is already running - quitting this instance")
            NSApp.terminate(nil)
        }
    }

    // MARK: - Status item and menu

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRightClick {
            showMenu()
        } else {
            toggleKeyboardBlocking()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let toggleItem = NSMenuItem(
            title: isKeyboardBlocked ? "Stop Blocking" : "Block Keyboard",
            action: #selector(menuToggleBlocking), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let autoUnlockItem = NSMenuItem(
            title: "Auto-Unlock After 5 Minutes",
            action: #selector(toggleAutoUnlock), keyEquivalent: "")
        autoUnlockItem.target = self
        autoUnlockItem.state = autoUnlockEnabled ? .on : .off
        menu.addItem(autoUnlockItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About KeyboardCleaner", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit KeyboardCleaner", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        // Temporarily attach the menu so left-click keeps the one-click toggle
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }

    @objc private func menuToggleBlocking() {
        toggleKeyboardBlocking()
    }

    @objc private func toggleAutoUnlock() {
        UserDefaults.standard.set(!autoUnlockEnabled, forKey: Self.autoUnlockKey)
        if isKeyboardBlocked {
            autoUnlockEnabled ? startAutoUnlockTimer() : cancelAutoUnlockTimer()
        }
        updateStatusItem()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private var autoUnlockEnabled: Bool {
        UserDefaults.standard.bool(forKey: Self.autoUnlockKey)
    }

    @objc private func toggleKeyboardBlocking() {
        if isKeyboardBlocked {
            stopBlocking()
            isKeyboardBlocked = false
        } else {
            // Only report "blocked" if the tap actually exists - otherwise the
            // menu bar shows a lock while every keystroke goes through.
            isKeyboardBlocked = startBlocking()
        }
        updateStatusItem()
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }
        let symbolName = isKeyboardBlocked ? "lock.fill" : "keyboard"
        let description = isKeyboardBlocked ? "Keyboard blocked" : "Keyboard enabled"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description) {
            image.isTemplate = true
            button.image = image
            button.title = isKeyboardBlocked && autoUnlockEnabled
                ? String(format: " %d:%02d", remainingSeconds / 60, remainingSeconds % 60)
                : ""
        } else {
            // Fallback for systems without SF Symbols
            button.image = nil
            button.title = isKeyboardBlocked ? "🔒" : "🧹"
        }
        button.toolTip = isKeyboardBlocked
            ? "Keyboard is BLOCKED - Click to enable, right-click for menu"
            : "Keyboard is enabled - Click to block for cleaning, right-click for menu"
    }

    // MARK: - Auto-unlock timer

    private func startAutoUnlockTimer() {
        cancelAutoUnlockTimer()
        remainingSeconds = Self.autoUnlockSeconds
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            if self.remainingSeconds <= 0 {
                print("Auto-unlock: re-enabling keyboard")
                self.toggleKeyboardBlocking()
            } else {
                self.updateStatusItem()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        autoUnlockTimer = timer
    }

    private func cancelAutoUnlockTimer() {
        autoUnlockTimer?.invalidate()
        autoUnlockTimer = nil
        remainingSeconds = 0
    }

    // MARK: - Event tap

    @discardableResult
    private func startBlocking() -> Bool {
        // Create event tap to intercept keyboard events, including the F-row
        // special functions which arrive as NX_SYSDEFINED instead of keyDown
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
            | (1 << Self.nxSysDefined)

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) in
                // macOS disables taps it considers unresponsive - re-enable immediately,
                // otherwise blocking would silently stop
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let refcon = refcon {
                        let delegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                        delegate.reenableTap()
                    }
                    return nil
                }

                if type.rawValue == AppDelegate.nxSysDefined {
                    guard let nsEvent = NSEvent(cgEvent: event) else {
                        return Unmanaged.passUnretained(event)
                    }
                    let auxKeyCode = Int((nsEvent.data1 & 0xFFFF0000) >> 16)
                    return AppDelegate.shouldSwallowSysDefined(subtype: nsEvent.subtype.rawValue,
                                                               auxKeyCode: auxKeyCode)
                        ? nil
                        : Unmanaged.passUnretained(event)
                }

                // Return nil to discard the event (block it)
                return nil
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap = eventTap else {
            print("Failed to create event tap. Make sure accessibility permissions are enabled.")
            showAccessibilityAlert()
            return false
        }

        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        if autoUnlockEnabled {
            startAutoUnlockTimer()
        }

        print("Keyboard blocking started")
        return true
    }

    fileprivate func reenableTap() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            print("Event tap was disabled by the system - re-enabled")
        }
    }

    private func stopBlocking() {
        cancelAutoUnlockTimer()

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        print("Keyboard blocking stopped")
    }

    // MARK: - Accessibility permissions

    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options)

        if !isAccessibilityEnabled {
            showAccessibilityAlert()
        } else {
            print("Accessibility permissions already granted")
        }
    }

    private func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions Required"
            alert.informativeText = "KeyboardCleaner needs accessibility permissions to block keyboard input. Please enable it in System Settings > Privacy & Security > Accessibility."
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Settings > Privacy & Security > Accessibility
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Keep the app running
app.run()
