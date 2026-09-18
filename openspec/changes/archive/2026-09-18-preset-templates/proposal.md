## Why

Preset management in Settings is broken: the "Add preset" field is bound to a constant (`text: .constant("")`), there is no way to edit or delete presets, and Settings writes a comma-joined string while `SelectionAssistantCoordinator.presets` reads a `stringArray` from the same key — so nothing edited in Settings ever reaches the panel. At the same time presets are bare names rendered as `[Translate] ` prefixes, which gives the model no instruction. This change makes presets usable and expressive.

## What Changes

- Settings: presets become a full CRUD list — add, rename, edit, delete, reorder.
- Presets become templates: `{{text}}` placeholder marks where selected text is inserted. Example: `Translate to English: {{text}}`.
- Backward compatibility: legacy plain preset names (no `{{text}}`) expand to `<name>\n\n<selected text>`; legacy comma-separated string storage is migrated to the new structured format on first read.
- Panel buttons render preset names; chat pipeline expands the template instead of `[Name] text` prefix.
- Fix storage mismatch: single source of truth for presets in UserDefaults, same encoding read by Settings, coordinator, and panel.

## Capabilities

### New Capabilities
- `preset-templates`: Preset CRUD in Settings (add, edit, delete, reorder), template format with `{{text}}` placeholder, expansion rules, storage format and legacy migration.

### Modified Capabilities
- `actionbar-overlay`: Panel preset buttons now derive from structured preset objects (name + template) instead of plain name strings; preset passed to chat pipeline is the template, not the name.
- `selection-snapshot`: Routing requirement changes — preset template expands into the user message (`{{text}}` replaced by selected text) instead of `[Preset] name` prefix.

## Impact

- `LightweightChat/Sources/SettingsView.swift` — presets section rebuilt: editable list UI.
- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantCoordinator.swift` — `presets` reads new storage format, passes templates.
- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantPanel.swift` — buttons from preset objects.
- `LightweightChat/Sources/ChatViewModel.swift` — `send(_:preset:)` expands `{{text}}` template.
- `LightweightChat/Sources/App.swift` — notification payload carries template.
- UserDefaults key `selection_presets` — value format changes (string array of names → JSON array of `{name, template}`); one-time migration.
- No API/network changes; request format stays OpenAI-compatible chat completions.
