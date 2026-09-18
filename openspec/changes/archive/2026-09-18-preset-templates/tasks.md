## 1. Preset model and storage

- [x] 1.1 Add `PresetTemplate: Codable` struct (`name`, `template`) in `Sources/SelectionAssistant/SelectionSnapshot.swift` or new file; verify `swift build` passes
- [x] 1.2 Add `PresetStore` helper: decode JSON array from `selection_presets`, lazy-migrate legacy comma-separated string to JSON, fall back to defaults `Translate`/`Summarize`; save via JSONEncoder; verify with temp UserDefaults values (legacy string, JSON, missing) in a debug print or REPL check
- [x] 1.3 Switch `SelectionAssistantCoordinator.presets` to `[PresetTemplate]` via `PresetStore`; verify `swift build` passes

## 2. Settings UI (CRUD)

- [x] 2.1 Rebuild Selection Assistant presets Section in `SettingsView.swift`: `List` rows with inline name + template TextFields bound to `@State` array, persistence on edit; verify typing persists after reopening Settings
- [x] 2.2 Add working "Add preset" row (replaces `text: .constant("")` dead field): appends empty `PresetTemplate` and focuses name field; verify new preset appears and persists
- [x] 2.3 Add delete (minus/swipe) and reorder (move up/down handles) with `onMove`-style persistence; verify order and deletion survive Settings reopen and app relaunch
- [x] 2.4 Add `{{text}}` hint caption in the Section; verify visible

## 3. Panel and routing

- [x] 3.1 Update `SelectionAssistantPanel` to take `[PresetTemplate]`, render `name` buttons, pass `template` in `onPresetSelected`; verify build
- [x] 3.2 Update `.selectionAssistantDirect` payload: `preset` → `template` key (coordinator panel callback and `App.swift` onReceive reader); verify build
- [x] 3.3 Update `ChatViewModel.send(_:preset:)` → `send(_:template:)`: expand `{{text}}` with selected text, else `template + "\n\n" + text`; direct mode sends raw text; verify by triggering Translate with a template `Translate to English: {{text}}` and checking user message content in chat

## 4. Verification

- [x] 4.1 `swift build -c debug` and `swift build -c release` pass
- [x] 4.2 End-to-end: add custom preset in Settings → select text → Option+Shift+Space (ActionBar mode) → custom button visible → click → user message shows expanded template → response arrives
- [x] 4.3 Migration check: install with legacy comma-separated `selection_presets` value → launch → presets visible in Settings as editable entries, key rewritten to JSON
