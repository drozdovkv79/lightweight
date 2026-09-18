## Why

Two focus problems degrade daily use. (1) The app has no menu bar presence — switching to it requires Dock hunting or ⌘Tab; a menu bar icon that opens and focuses the app on click is the fastest access path. (2) When the Selection Assistant sends a prompt (direct mode or preset click), the response streams into a window hidden behind the app the user is working in — they must manually switch to see the answer.

## What Changes

- Add a menu bar (status bar) item showing the dedicated tray icon (`locy_tray.jpeg`, circular-masked at runtime for alpha). Clicking it opens the app's main window and gives it keyboard focus (activates the app even when another app is frontmost).
- Replace the app icon: `AppIcon.icns` regenerated from `locy_icon.jpeg` (Dock, Finder, ⌘Tab).
- After a Selection Assistant prompt is dispatched to the chat (direct-mode trigger, or preset click in ActionBar mode), bring the app's main window to front and focus it, so the response is visible immediately.

## Capabilities

### New Capabilities
- `menu-bar-access`: Menu bar status item with app icon; click opens and focuses the app window.

### Modified Capabilities
- `selection-trigger`: New requirement — app window activates and receives focus when a selection-assistant prompt is dispatched to the chat pipeline.

## Impact

- `LightweightChat/Sources/App.swift` — AppDelegate: create `NSStatusItem` in `applicationDidFinishLaunching` (tray icon from bundled resource, runtime circular mask); activation helper shared by status item click and selection flow.
- `LightweightChat/Resources/AppIcon.icns` — regenerated from `locy_icon.jpeg` (sips + iconutil); `Info.plist` icon reference unchanged if filename stays `AppIcon`.
- `LightweightChat/Resources/locy_tray.jpeg` — bundled as resource for runtime load.
- `LightweightChat/Sources/ChatViewModel.swift` — none expected; activation happens at the dispatch site.
- Notification `.selectionAssistantDirect` handler in `App.swift` — append activation call after `chatVM.send(...)`.
- No storage, no network, no entitlement changes.
