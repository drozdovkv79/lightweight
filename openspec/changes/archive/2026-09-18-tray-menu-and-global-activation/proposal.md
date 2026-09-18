## Why

Three tray/activation gaps after the first tray iteration. (1) Tray icon has no menu — About and Quit are only reachable via Dock/app menu. (2) Closing the window with ⌘W then clicking the tray icon does not restore it: SwiftUI releases the NSWindow on close, so the `newWindowForTab` fallback never has anything to show — the window object must survive close instead. (3) Getting to the app to type a prompt requires mouse (Dock/tray); a global hotkey Control+Option+Command + any key that opens the window with focus in the prompt input is faster.

## What Changes

- Tray icon context menu with two items: `About…` (opens the existing About panel) and `Quit` (terminates the app). Left click keeps the current activate+focus behavior; right-click opens the menu.
- Window restore fix: main window's NSWindow is no longer released on close (`isReleasedWhenClosed = false`), so it survives ⌘W and tray click brings it back via `makeKeyAndOrderFront`. The `newWindowForTab:` fallback is removed as obsolete.
- Global activation hotkey: pressing Control+Option+Command together with any other key anywhere in the system opens the app window and focuses the prompt input. Implemented as a listen-only CGEventTap, which rides on the Accessibility permission the app already requests for the Selection Assistant.

## Capabilities

### New Capabilities
- `global-activation-hotkey`: System-wide Control+Option+Command + any key opens the app and focuses the prompt input.

### Modified Capabilities
- `menu-bar-access`: Window restore root-cause fix (window survives close); new context menu requirement (About…, Quit) shown on right-click.

## Impact

- `LightweightChat/Sources/WindowAccessor.swift` — `isReleasedWhenClosed = false`, keep registry.
- `LightweightChat/Sources/App.swift` — tray menu build + right-click handling; remove `newWindowForTab` fallback; `GlobalActivationMonitor` (CGEventTap) install at launch and after permission grant; activation helper unchanged.
- `LightweightChat/Sources/ChatInputField.swift` — `onReceive(.focusPromptInput)` → `focused = true`.
- Reuses existing Accessibility permission; no new entitlements, no storage changes.
