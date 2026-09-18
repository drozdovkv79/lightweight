# actionbar-overlay Specification

## Purpose
NSPanel overlay с preset кнопками, позиционированный возле выделенного текста для быстрого доступа к AI действиям.

## Requirements

### Requirement: Panel appearance and positioning
Overlay panel SHALL be NSPanel with `.borderless`, `.nonactivatingPanel` style, level `.statusBar`, positioned near selection rect.

#### Scenario: Panel opens near selection
- **WHEN** ActionBar mode triggers
- **THEN** NSPanel appears near selection rect with `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary]`

### Requirement: Preset buttons
Panel SHALL display preset buttons derived from stored preset objects (name + template). Default presets: Translate, Summarize. Button order SHALL match preset list order.

#### Scenario: Default presets shown
- **WHEN** panel opens
- **THEN** buttons for Translate and Summarize visible

#### Scenario: Panel reflects Settings changes
- **WHEN** user adds, edits, deletes, or reorders presets in Settings
- **THEN** next panel open shows the updated names and order

#### Scenario: Preset selected passes template
- **WHEN** user clicks a preset button
- **THEN** panel dismisses and the preset template (not just the name) is passed to the chat pipeline

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
