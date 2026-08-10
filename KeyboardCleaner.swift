import Cocoa
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isKeyboardBlocked: Bool = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure the button
        if let button = statusItem.button {
            button.title = "🧹"
            button.action = #selector(toggleKeyboardBlocking)
            button.target = self
            button.toolTip = "Click to block keyboard for cleaning"
        }
        
        // Initial state
        updateMenuTitle()
        
        // Request accessibility permissions
        DispatchQueue.main.async {
            self.requestAccessibilityPermissions()
        }
        
        print("KeyboardCleaner launched - look for the broom icon in your menu bar")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Ensure keyboard is re-enabled when app quits
        stopBlocking()
        print("KeyboardCleaner terminating - keyboard re-enabled")
    }
    
    @objc private func toggleKeyboardBlocking() {
        if isKeyboardBlocked {
            stopBlocking()
            isKeyboardBlocked = false
        } else {
            startBlocking()
            isKeyboardBlocked = true
        }
        updateMenuTitle()
    }
    
    private func updateMenuTitle() {
        if isKeyboardBlocked {
            statusItem.button?.title = "🔒"
            statusItem.button?.toolTip = "Keyboard is BLOCKED - Click to enable"
        } else {
            statusItem.button?.title = "🧹"
            statusItem.button?.toolTip = "Keyboard is enabled - Click to block for cleaning"
        }
    }
    
    private func startBlocking() {
        // Create event tap to intercept keyboard events
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) in
                // Return nil to discard the event (block it)
                return nil
            },
            userInfo: nil
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap. Make sure accessibility permissions are enabled.")
            showAccessibilityAlert()
            return
        }
        
        // Add to run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("Keyboard blocking started")
    }
    
    private func stopBlocking() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        
        print("Keyboard blocking stopped")
    }
    
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
