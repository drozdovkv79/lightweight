# selection-read Specification

## Purpose
Чтение выделенного текста из frontmost приложения через macOS Accessibility API.

## ADDED Requirements

### Requirement: Accessibility permission check
System SHALL check `AXIsProcessTrusted()` before attempting to read selection.

#### Scenario: Permission granted
- **WHEN** AX API is trusted
- **THEN** selection read proceeds

#### Scenario: Permission not granted
- **WHEN** AX API is not trusted
- **THEN** show permission request dialog via `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`

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
