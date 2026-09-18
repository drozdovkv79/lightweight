# actionbar-overlay Specification

## Purpose
NSPanel overlay с preset кнопками, позиционированный возле выделенного текста для быстрого доступа к AI действиям.

## ADDED Requirements

### Requirement: Panel appearance and positioning
Overlay panel SHALL be NSPanel with `.borderless`, `.nonactivatingPanel` style, level `.statusBar`, positioned near selection rect.

#### Scenario: Panel opens near selection
- **WHEN** ActionBar mode triggers
- **THEN** NSPanel appears near selection rect with `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary]`

### Requirement: Preset buttons
Panel SHALL display preset action buttons. Default presets: Translate, Summarize.

#### Scenario: Default presets shown
- **WHEN** panel opens
- **THEN** buttons for Translate and Summarize visible

### Requirement: Configurable custom presets
User SHALL configure custom presets in Settings. Presets stored in UserDefaults.

#### Scenario: User adds custom preset
- **WHEN** user adds custom preset name in Settings
- **THEN** preset appears as button on panel

### Requirement: Direct mode bypass
Direct mode SHALL send selection to chat immediately without showing panel.

#### Scenario: Direct mode
- **WHEN** user triggers in direct mode (default or setting)
- **THEN** no panel shown; text sent to chat immediately

### Requirement: Panel dismiss
Panel SHALL dismiss on outside click and on preset button selection.

#### Scenario: Outside click
- **WHEN** user clicks outside panel
- **THEN** panel orderOut

#### Scenario: Preset selected
- **WHEN** user clicks preset button
- **THEN** panel dismisses and selection sent to chat with preset
