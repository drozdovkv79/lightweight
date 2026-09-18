# selection-read Specification

## Purpose
Чтение выделенного текста из frontmost приложения через macOS Accessibility API.

## Requirements

### Requirement: Accessibility permission check
System SHALL check `AXIsProcessTrusted()` before attempting to read selection, and SHALL prompt proactively at app launch rather than waiting for the first hotkey press (global key monitors cannot fire before permission is granted — catch-22 otherwise).

#### Scenario: Permission granted
- **WHEN** AX API is trusted
- **THEN** selection read proceeds

#### Scenario: Permission not granted
- **WHEN** AX API is not trusted
- **THEN** show permission request dialog via `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`

#### Scenario: Proactive prompt at launch
- **WHEN** app launches with feature enabled and AX permission not granted
- **THEN** system prompt is shown automatically and in-app alert appears once per session with "Open System Settings" button opening `Privacy_Accessibility` pane

### Requirement: Read selected text from frontmost app
System SHALL read selected text via AX API from frontmost application.

#### Scenario: Text is selected
- **WHEN** user has text selected in any AX-compatible app
- **THEN** system returns selected string via `kAXSelectedTextAttribute`

#### Scenario: No text selected
- **WHEN** no text is selected
- **THEN** system returns nil

#### Scenario: App has limited AX support
- **WHEN** frontmost app is browser/WebKit with limited AX
- **THEN** system returns nil gracefully (no crash)

### Requirement: Accessibility permission persists across launches
Permission grant SHALL persist in macOS System Settings until explicitly revoked.

#### Scenario: Permission revoked
- **WHEN** user revokes accessibility permission in System Settings
- **THEN** next trigger shows permission request dialog again

#### Scenario: In-app notice throttling
- **WHEN** user repeatedly triggers without permission within one session
- **THEN** system TCC prompt is invoked, but in-app alert appears only once per session
