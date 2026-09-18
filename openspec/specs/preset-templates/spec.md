# preset-templates Specification

## Purpose
Preset templates: управление пресетами в Settings (добавление, редактирование, удаление, сортировка) и шаблоны с плейсхолдером `{{text}}`, определяющие, как выделенный текст превращается в user message.

## Requirements

### Requirement: Preset CRUD in Settings
Settings SHALL provide a preset list editor supporting add, edit (name and template), delete, and reorder of presets.

#### Scenario: User adds preset
- **WHEN** user enters a name and template and confirms add in Settings
- **THEN** preset persists to UserDefaults and appears in the list

#### Scenario: User edits preset
- **WHEN** user changes preset name or template in Settings
- **THEN** changes persist immediately

#### Scenario: User deletes preset
- **WHEN** user removes a preset in Settings
- **THEN** preset disappears from the list and from the Selection Assistant panel on next trigger

#### Scenario: User reorders presets
- **WHEN** user moves a preset up or down in Settings
- **THEN** new order persists and is reflected in panel button order

### Requirement: Template format with {{text}} placeholder
A preset SHALL consist of a display name and a template string. The template SHALL support a `{{text}}` placeholder marking where the selected text is inserted.

#### Scenario: Template with placeholder
- **WHEN** preset template is `Translate to English: {{text}}` and selected text is `Hello`
- **THEN** user message content is `Translate to English: Hello`

#### Scenario: Template without placeholder
- **WHEN** preset template does not contain `{{text}}`
- **THEN** selected text is appended after the template separated by a blank line: `<template>\n\n<selected text>`

### Requirement: Preset storage format
Presets SHALL be stored in UserDefaults under `selection_presets` as a JSON array of `{name: String, template: String}` objects, readable consistently by Settings, coordinator, and panel.

#### Scenario: Legacy comma-separated value migrated
- **WHEN** `selection_presets` contains a legacy plain string (e.g. `Translate,Summarize`)
- **THEN** on first read it is migrated to JSON objects with name and template equal to the name, and legacy value is replaced

#### Scenario: Legacy bare-name entries preserved
- **WHEN** existing presets are plain names without `{{text}}`
- **THEN** they remain valid and expand via the no-placeholder rule

#### Scenario: Empty or corrupted storage
- **WHEN** `selection_presets` is missing, empty, or unparseable
- **THEN** defaults (`Translate`, `Summarize`) are used
