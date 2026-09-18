# insert-back Specification

## Purpose
Запись AI результата обратно в оригинальное выделение текста в исходном приложении через AX API.

## Requirements

### Requirement: Insert button on assistant messages
Each assistant message SHALL show "Insert Selection" button on toolbar when associated SelectionSnapshot exists.

#### Scenario: Snapshot present
- **WHEN** assistant message has associated snapshot
- **THEN** "Insert Selection" button visible on message toolbar

#### Scenario: No snapshot
- **WHEN** assistant message has no associated snapshot
- **THEN** no insert button shown

### Requirement: AX write replacement
System SHALL write replacement text via `AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute, replacement)`.

#### Scenario: Insert back succeeds
- **WHEN** user clicks Insert Selection
- **THEN** AI result replaces selected text in original app

#### Scenario: Insert back fails
- **WHEN** AX write fails (app terminated, no permission)
- **THEN** show error alert, no crash

### Requirement: Original app identification
Snapshot SHALL store `appBundleIdentifier` to target correct process for AX write.

#### Scenario: Write to correct app
- **WHEN** insert back triggered
- **THEN** AX element created for original app PID from snapshot

### Requirement: Insert back with direct mode
Direct mode messages SHALL also support insert back when snapshot was captured.

#### Scenario: Direct mode insert back
- **WHEN** user sends selection via direct mode
- **THEN** snapshot stored and insert back available on response
