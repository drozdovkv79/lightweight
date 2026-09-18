## ADDED Requirements


## MODIFIED Requirements

### Requirement: Global hotkey invoke
The system SHALL register `Cmd+Shift+Space` as the default global hotkey via Carbon `RegisterEventHotKey`, SHALL check the returned `OSStatus`, and on registration failure (combination conflict) SHALL fall back to a listen-only CGEvent tap matching the same modifier+key combination (requires Accessibility, which the feature already needs for reading selection). The combination SHALL be configurable in Settings. Registration success/failure SHALL be logged (os_log/NSLog diagnostics) so silent failure is impossible.

#### Scenario: User presses hotkey
- **WHEN** user presses `Cmd+Shift+Space` in any app
- **THEN** selection assistant triggers: reads selection and routes to chat

#### Scenario: Registration conflict
- **WHEN** `RegisterEventHotKey` fails (another app or system owns the combination) or the combination is unavailable
- **THEN** CGEvent tap fallback fires the same trigger, and the failure is logged with the OSStatus code

#### Scenario: Hotkey fires without permissions
- **WHEN** app has no Accessibility permission
- **THEN** trigger still fires and permission prompt is shown for selection reading

#### Scenario: Permission alert text matches actual hotkey
- **WHEN** in-app permission alert is shown
- **THEN** alert text names the currently configured hotkey, not a stale one

### Requirement: Debounce on auto-invoke
Auto-invoke from mouse events SHALL be debounced with the configurable `auto_invoke_delay` setting (default 0.3s) to prevent rapid-fire during drag; no hardcoded delay.

#### Scenario: Debounce during drag
- **WHEN** user drags mouse during selection
- **THEN** only one trigger fires after drag ends, debounced by the configured delay

#### Scenario: Delay changed in Settings
- **WHEN** user sets `auto_invoke_delay` to a different value
- **THEN** next auto-invoke uses the new delay without relaunch

