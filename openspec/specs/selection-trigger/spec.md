# selection-trigger Specification

## Purpose
Обнаружение выделения текста пользователем через глобальный горячий клавиш или мышь для запуска AI assistant.

## Requirements

### Requirement: Global hotkey invoke
The system SHALL register `Option+Shift+Space` as a global hotkey via Carbon `RegisterEventHotKey`, which requires no Accessibility or Input Monitoring permission to fire (unlike `NSEvent.addGlobalMonitorForEvents(.keyDown)`).

#### Scenario: User presses hotkey
- **WHEN** user presses `Option+Shift+Space` in any app
- **THEN** selection assistant triggers: reads selection and routes to chat

#### Scenario: Hotkey fires without permissions
- **WHEN** app has no Accessibility or Input Monitoring permission
- **THEN** hotkey still triggers and permission prompt is shown for selection reading

### Requirement: Feature enablement gating
Hotkey and mouse monitors SHALL be registered only while the feature is enabled; the Settings toggle SHALL re-register or unregister them live (UserDefaults-backed, no relaunch needed).

#### Scenario: Feature disabled via Settings
- **WHEN** user disables Selection Assistant in Settings
- **THEN** hotkey unregistered (`UnregisterEventHotKey`), mouse monitors removed

#### Scenario: Feature re-enabled via Settings
- **WHEN** user enables Selection Assistant in Settings
- **THEN** hotkey and mouse monitors registered immediately (idempotent — no duplicates)

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

### Requirement: App activation on assistant invocation
When a selection-assistant prompt is dispatched to the chat pipeline (direct-mode trigger or preset click in ActionBar mode), the app SHALL bring its main window to front and give it keyboard focus, so the streamed response is visible immediately.

#### Scenario: Direct mode dispatch
- **WHEN** a selection is sent to the chat via direct mode trigger
- **THEN** app activates and main window receives keyboard focus

#### Scenario: Preset click dispatch
- **WHEN** user clicks a preset button on the action bar panel
- **THEN** app activates and main window receives keyboard focus as the response begins
