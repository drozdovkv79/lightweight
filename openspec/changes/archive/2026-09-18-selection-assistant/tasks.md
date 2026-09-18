## 1. Remove app sandbox

- [x] Remove sandbox entitlement from Info.plist
- [x] Add `com.apple.security.automation.apple-events` entitlement
- [x] Verify build succeeds

## 2. Create SelectionSnapshot model

- [x] Create `SelectionSnapshot` struct with `selectedText`, `appBundleIdentifier`, `canReplaceSelection`

## 3. Create SelectionAssistantTriggerMonitor

- [x] Register global hotkey `Option+Shift+Space`
- [x] Monitor leftMouseUp for drag ≥3pt
- [x] Monitor double-click via clickCount
- [x] Debounce via DispatchWorkItem
- [x] Outside-click dismiss monitor

## 4. Create SelectionAssistantCoordinator

- [x] Check settings enabled
- [x] Check AX permission (`AXIsProcessTrusted`)
- [x] Request permission if needed
- [x] Read selection via AX API
- [x] Validate not empty
- [x] Route to Direct or ActionBar mode

## 5. Create SelectionAssistantPanel (ActionBar)

- [x] NSPanel with `.borderless`, `.nonactivatingPanel`, level `.statusBar`
- [x] Position near selection rect
- [x] Preset buttons from UserDefaults
- [x] Dismiss on outside click
- [x] Dismiss on preset selection

## 6. Extend ChatViewModel

- [x] Add `selectionSnapshotsByAssistantID: [UUID: SelectionSnapshot]`
- [x] Add `send(selectionSnapshot:)` storing snapshot by message ID
- [x] Expose snapshot for insert-back query by message ID

## 7. Implement Insert Back

- [x] Add "Insert Selection" button on assistant message toolbar (conditional on snapshot)
- [x] AX write via `AXUIElementSetAttributeValue(kAXSelectedTextAttribute)`
- [x] Error handling for failed AX write

## 8. Add preset configuration to Settings

- [x] Editable preset list in SettingsView
- [x] UserDefaults storage for presets
- [x] Default presets: Translate, Summarize

## 9. Wire up in App.swift

- [x] Register hotkey in AppDelegate
- [x] Start mouse monitor on app launch
- [x] Handle accessibility permission flow

## 10. Update ContentView

- [x] Insert button on MessageRow for assistant messages with snapshot
- [x] Connect Insert button to ChatViewModel insert-back action
