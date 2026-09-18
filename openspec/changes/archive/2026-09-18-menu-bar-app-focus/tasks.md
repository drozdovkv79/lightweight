## 1. Activation helper

- [x] 1.1 Add `activateMainWindow()` to `AppDelegate`: `NSApp.activate(ignoringOtherApps: true)` + find main window via `WindowAccessor` registry (or `NSApp.windows.first(where: { $0.canBecomeMain })`) and `makeKeyAndOrderFront(nil)` + `makeKey`; verify `swift build` passes
- [x] 1.2 Closed-window fallback: notification `.reopenMainWindow` → in `ContentView` (has `@Environment(\.openWindow)`) call `openWindow(id:)`; helper posts it when no window found; verify build

## 2. App icon

- [x] 2.1 Generate `AppIcon.icns` from `Resources/locy_icon.jpeg`: `sips` resize to iconset sizes (16,32,64,128,256,512,1024 with @2x) → `iconutil -c icns`; replace existing `Resources/AppIcon.icns`; verify `Info.plist` `CFBundleIconFile` points to `AppIcon` and `swift build` passes

## 3. Menu bar status item

- [x] 3.1 Tray icon: load `locy_tray.jpeg` from bundle, render 18×18 NSImage with circular clip (transparent corners), cache in AppDelegate; verify build
- [x] 3.2 In `AppDelegate.applicationDidFinishLaunching`: create `NSStatusItem`, set button image to masked tray icon (`isTemplate = false`), add target/action → `activateMainWindow()`; store strong reference; verify build
- [ ] 3.3 Verify icon renders legibly in light and dark menu bar (no opaque square background)

## 4. Activation on selection dispatch

- [x] 4.1 In `App.swift` `.selectionAssistantDirect` onReceive: call `appDelegate.activateMainWindow()` after `chatVM.send(...)`; verify build

## 5. Verification

- [x] 5.1 `swift build -c debug` and `swift build -c release` pass
- [ ] 5.2 Runtime check (Finder launch): new app icon in Dock/Finder; menu bar tray icon visible in both modes; click from another app → window front + focused; ⌘W then click → window reopens; direct-mode selection trigger → window front; preset click → window front
