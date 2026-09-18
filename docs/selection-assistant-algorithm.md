# Selection Assistant Algorithm

Cross-app text selection → AI processing → result insertion back into original app.

## Architecture

```
User selects text (any app)
        ↓
┌───────────────────────────────────────┐
│ Trigger Layer                         │
│  • GlobalHotKey (Option+Shift+Space)  │
│  • SelectionAutoInvokeMonitor         │
│    - leftMouseUp → check drag ≥3pt    │
│    - or double-click                  │
│    - debounced auto-invoke            │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│ SelectionAssistantCoordinator         │
│  1. Check settings enabled            │
│  2. Check accessibility permission    │
│  3. Read selected text via AX API     │
│  4. Validate not empty                │
│  5. Route to mode                     │
└───────┬───────────────┬───────────────┘
        ↓               ↓
┌──────────────┐ ┌──────────────────────┐
│ Direct Mode  │ │ ActionBar Mode       │
│ Skip UI,     │ │ Show NSPanel overlay │
│ send to chat │ │ with preset buttons  │
│ immediately  │ │ positioned near      │
│              │ │ selection rect       │
└──────┬───────┘ └──────────┬───────────┘
       └────────┬───────────┘
                ↓
┌───────────────────────────────────────┐
│ Chat Pipeline                         │
│  • CommandCenter.ask(text, preset,    │
│    selectionSnapshot)                  │
│  • ChatViewModel stores snapshot by   │
│    assistant message ID               │
│  • AI response rendered in chat       │
└───────────────┬───────────────────────┘
                ↓
┌───────────────────────────────────────┐
│ Insert Back (optional)                │
│  • "Insert Selection" button on       │
│    message toolbar                    │
│  • AccessibilitySelectionReplacement  │
│    Writer writes AI result into       │
│    original text selection via AX API │
└───────────────────────────────────────┘
```

## Key Components

### 1. Trigger Detection

```swift
// Global mouse monitor — catches selection in any app
NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { event in
    let dragDistance = abs(event.locationInWindow.x - self.mouseDownPoint.x)
    let dragVertical = abs(event.locationInWindow.y - self.mouseDownPoint.y)
    
    if dragDistance >= 3 || dragVertical >= 3 {
        // Drag selection — auto-invoke
        coordinator.scheduleAutomaticTrigger()
    }
    // Double-click also triggers
    return event
}
```

### 2. Accessibility Text Reading

```swift
// Read selected text from frontmost app via AX API
func readSelection() async -> String? {
    let app = NSWorkspace.shared.frontmostApplication
    let axApp = AXUIElementCreateApplication(app?.processIdentifier ?? 0)
    
    // Get focused UI element
    var focusedElement: AnyObject?
    AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElement)
    
    // Get selected text range
    var selectedText: AnyObject?
    AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, 
                                   kAXSelectedTextAttribute as CFString, 
                                   &selectedText)
    return selectedText as? String
}
```

### 3. Overlay Panel (ActionBar Mode)

```swift
// NSPanel positioned near selection, not SwiftUI context menu
let panel = NSPanel(
    contentRect: NSRect(origin: panelOrigin, size: .zero),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .statusBar
panel.isOpaque = false
panel.backgroundColor = .clear
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### 4. Snapshot → Chat → Replace

```swift
// Store snapshot when sending to chat
struct SelectionSnapshot {
    let selectedText: String
    let appBundleIdentifier: String
    let canReplaceSelection: Bool
}

// ChatViewModel stores by message ID
func send(selectionSnapshot: SelectionSnapshot?) {
    selectionSnapshotsByAssistantID[currentAssistantMessageID] = selectionSnapshot
}

// Insert back writes to original app
func insertSelection(originalText: String, replacement: String, appPID: pid_t) {
    let axApp = AXUIElementCreateApplication(appPID)
    // Set selected text to replacement
    AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, replacement as CFString)
}
```

## Implementation Patterns

### Permission Check

```swift
// macOS requires Accessibility permission for AX API
if !AXIsProcessTrusted() {
    // Show permission request dialog
    AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true])
    return
}
```

### Debounce (Auto-Invoke)

```swift
// Prevent rapid-fire triggers during drag
func scheduleAutomaticTrigger() {
    autoInvokeWorkItem?.cancel()
    autoInvokeWorkItem = DispatchWorkItem { [weak self] in
        self?.trigger()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + settings.autoInvokeDelay, 
                                   execute: autoInvokeWorkItem!)
}
```

### Outside Click Dismiss

```swift
// Dismiss overlay on click outside
NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
    if !panel.frame.contains(NSEvent.mouseLocation) {
        panel.orderOut(nil)
    }
    return event
}
```

## Notes

- No `.contextMenu` SwiftUI modifier — raw NSPanel only
- Accessibility permission required on first use
- Code signature changes reset Accessibility grants
- Works across all apps that implement AX API (most native macOS apps)
- Browser/WebKit apps may have limited AX support
