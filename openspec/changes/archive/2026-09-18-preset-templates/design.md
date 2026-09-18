## Context

Preset flow today: `SettingsView` (SettingsView.swift:9,14-17) stores comma-joined string in `@AppStorage("selection_presets")`; `SelectionAssistantCoordinator.presets` (SelectionAssistantCoordinator.swift:21-24) reads `stringArray(forKey:)` from the same key — type mismatch, edits never reach the panel. "Add preset" TextField is bound to `.constant("")` — dead. `ChatViewModel.send(_:preset:)` (ChatViewModel.swift:113-125) builds `[Preset] text`. Panel buttons take `[String]`. Feature flag: `selection_assistant_enabled` (live-computed, hotkey reregisters on toggle).

Constraints: no tests exist; SwiftUI Settings sheet 460x460; macOS 14+; storage must stay in plain UserDefaults (no files, no Keychain).

## Goals / Non-Goals

**Goals:**
- Single consistent storage encoding for presets, read identically by Settings, coordinator, panel.
- Working add/edit/delete/reorder in Settings with immediate persistence.
- Template expansion with `{{text}}` at the single point where user message content is built.

**Non-Goals:**
- Per-preset model or system-prompt overrides (future scope).
- Multi-placeholder templates (only `{{text}}`).
- Preset import/export, iCloud sync.

## Decisions

- **Storage: JSON string in UserDefaults `selection_presets`** — `[{name, template}]` encoded via `Codable` struct `PresetTemplate`. Alternatives: `stringArray` of `name|template` pairs (fragile parsing, names could contain `|`), plist archive (less debuggable). JSON string survives UserDefaults type system; single key, atomic writes.
- **Migration: lazy, on read.** A shared `PresetStore` helper decodes: JSON array → use; plain comma-separated string → split, map each to `{name: s, template: s}`, rewrite key as JSON; nil/empty → defaults. Migration runs once (subsequent reads see JSON). Comma-separated legacy values containing commas in names are lost — acceptable, names were constrained by the old comma UI anyway.
- **Expansion: in `ChatViewModel.send(_:preset:)` rename to `send(_:template:)`.** `template.replacingOccurrences(of: "{{text}}", with: text)`; if no placeholder → `template + "\n\n" + text`. Expansion lives here and only here — panel and coordinator never expand.
- **Notification payload**: `.selectionAssistantDirect` userInfo carries `template` (String) instead of `preset`. Panel buttons pass whole `PresetTemplate`; only `template` travels through notification.
- **Settings UI: `List`-based editor inside existing Section** — rows with `TextField` (name) + `TextField` (template) inline, delete via swipe/minus, reorder via `onMove`, add via dedicated "Add preset" row that appends an empty template and focuses its name field. Alternatives: sheet-per-preset editor (more taps, not needed), `.textEditor` (overkill for one-liners). `{{text}}` hint text shown under section.
- **Defaults**: `Translate` / `Summarize` as bare names → templates equal to name (expand via no-placeholder rule).

## Risks / Trade-offs

- [Old app version reads new JSON value] → `stringArray(forKey:)` on a JSON string returns nil, coordinator falls back to defaults; no crash. Forward migration ignored.
- [User template contains literal `{{text}}` they want verbatim] → no escaping mechanism; documented behavior, unlikely.
- [Inline edit loses focus on list reorder] → reorder via explicit move handles only, not drag, to avoid first-responder churn.
- [UserDefaults read on every panel open] → negligible; presets list is tiny, no caching layer needed.

## Migration Plan

No deploy steps: single binary reads/writes one key; migration is lazy at first read after update. Rollback = revert commit; old build reads JSON as nil → defaults shown, user presets temporarily invisible (not lost — key rewritten only when legacy value detected, JSON untouched by old build).

## Open Questions

None.
