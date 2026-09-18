## 1. Window restore root-cause fix

- [x] 1.1 `WindowAccessor.makeNSView`: add `window.isReleasedWhenClosed = false` (keep registry assignment); verify `swift build` passes
- [x] 1.2 `AppDelegate.activateMainWindow()`: remove `newWindowForTab:` fallback branch (window now survives close; keep registry → `makeKeyAndOrderFront` path); verify build

## 2. Tray context menu

- [x] 2.1 `statusItemClicked`: register action for `[.leftMouseUp, .rightMouseUp]` (`button.sendAction(on:)`), branch on `NSApp.currentEvent?.type == .rightMouseUp`; right-click → build menu (`About…` → `AboutPanel.show()`, `Quit` → `NSApp.terminate(nil)`), show via `statusItem.menu` + `performClick`, reset `menu = nil`; left click → `activateMainWindow()`; verify build
- [x] 2.2 Verify right-click menu shows both items and both actions work; left click does not show menu

## 3. Global activation hotkey

- [x] 3.1 Create `Sources/GlobalActivationMonitor.swift`: listen-only CGEventTap on keyDown; callback checks flags ⊇ Control+Option+Command (без SecondaryFn) → dispatch to main: `onActivate()` closure; tap port + run loop source retained; `start()` returns success (nil if no Accessibility), `stop()` invalidates; verify build
- [x] 3.2 Wire in `AppDelegate`: own monitor, `start()` at launch; if start failed (no permission) retry after permission grant (hook in `checkPermissionPromptIfNeeded` flow); onActivate → `activateMainWindow()` + post `.focusPromptInput`; verify build
- [x] 3.3 `ChatInputField`: add `.onReceive(NotificationCenter.publisher(for: .focusPromptInput)) { focused = true }`; verify build

## 4. Verification

- [x] 4.1 `swift build -c debug` and `swift build -c release` pass
- [x] 4.2 Runtime (Finder launch): ⌘W → tray left-click restores same window with focus; right-click → About… opens panel, Quit terminates (server killed); from another app Cmd+Ctrl+Opt+letter → window front + prompt focused; event passes through to the other app; modifier-only press does nothing

## 5. Fixes from runtime feedback (session 2)

- [x] 5.1 Window restore root-cause: `WindowRegistry.mainWindow` weak → strong (SwiftUI releases NSWindow after ⌘W despite isReleasedWhenClosed=false); retire stale window on scene recreate; verify build
- [x] 5.2 Hotkey toggle: when app already frontmost, second press returns focus to `previousApp` (captured at each activation); spec delta updated with Toggle back scenario; verify build
