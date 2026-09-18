# selection-trigger Specification

## Purpose
Обнаружение выделения текста пользователем через глобальный горячий клавиш или мышь для запуска AI assistant.

## ADDED Requirements

### Requirement: Global hotkey invoke
The system SHALL register `Option+Shift+Space` as global hotkey triggering selection assistant.

#### Scenario: User presses hotkey
- **WHEN** user presses `Option+Shift+Space` in any app
- **THEN** selection assistant triggers: reads selection and routes to chat

### Requirement: Mouse drag invoke
The system SHALL detect text selection via `leftMouseUp` where drag distance ≥3pt in either axis.

#### Scenario: Drag selection triggers invoke
- **WHEN** user drags to select text and releases left mouse ≥3pt from mouse-down
- **THEN** system schedules debounced auto-invoke

### Requirement: Double-click invoke
The system SHALL detect double-click as selection trigger.

#### Scenario: Double-click triggers invoke
- **WHEN** user double-clicks to select text
- **THEN** selection assistant triggers immediately (no debounce)

### Requirement: Debounce on auto-invoke
Auto-invoke from mouse events SHALL be debounced with configurable delay to prevent rapid-fire during drag.

#### Scenario: Debounce during drag
- **WHEN** user drags mouse during selection
- **THEN** only one trigger fires after drag ends (debounced)

### Requirement: Outside-click dismiss
Overlay panel SHALL dismiss on click outside panel frame.

#### Scenario: Click outside panel
- **WHEN** user clicks outside panel bounds
- **THEN** panel orderOut and dismisses
