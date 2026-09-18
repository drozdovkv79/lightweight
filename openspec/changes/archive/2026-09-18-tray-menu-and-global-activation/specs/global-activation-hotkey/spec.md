## Purpose
Глобальный хоткей Control+Option+Command + любая клавиша: окно приложения открывается и фокус встаёт в поле ввода промпта, из любого приложения.

## ADDED Requirements

### Requirement: Global activation hotkey
Pressing Control+Option+Command together with any non-modifier key anywhere in the system SHALL activate the app, bring the main window to front, and focus the prompt input. The hotkey SHALL NOT swallow or alter the key event. The hotkey acts as a toggle: when the app is already frontmost, pressing it again SHALL return focus to the application that was frontmost before the last activation.

#### Scenario: Hotkey from another app
- **WHEN** user presses Control+Option+Command and any letter key while another app is frontmost
- **THEN** app activates, main window comes to front, and the prompt input receives keyboard focus

#### Scenario: Toggle back
- **WHEN** the app was activated by the hotkey and user presses the same combination again
- **THEN** focus returns to the application that was frontmost before the activation

#### Scenario: Event passes through
- **WHEN** the hotkey combination is pressed
- **THEN** the key event is not consumed by the app (listen-only monitoring)

#### Scenario: Modifier-only press ignored
- **WHEN** user presses only the modifier keys (Control+Option+Command) without another key
- **THEN** nothing happens

#### Scenario: Works without Accessibility
- **WHEN** Accessibility permission is not granted
- **THEN** the hotkey is inactive and no crash occurs; it starts working as soon as permission is granted (same permission the Selection Assistant already requests)
