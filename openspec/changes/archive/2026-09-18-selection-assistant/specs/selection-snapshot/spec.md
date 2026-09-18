# selection-snapshot Specification

## Purpose
Снапшот контекста выделения передаётся в чат и привязывается к assistant сообщению.

## ADDED Requirements

### Requirement: Snapshot structure
SelectionSnapshot SHALL contain: `selectedText: String`, `appBundleIdentifier: String`, `canReplaceSelection: Bool`.

#### Scenario: Snapshot created
- **WHEN** selection assistant triggers with valid selection
- **THEN** SelectionSnapshot created with selected text, bundle ID of frontmost app, and AX replace capability flag

### Requirement: Snapshot stored by assistant message ID
ChatViewModel SHALL store snapshot keyed by assistant message ID in `selectionSnapshotsByAssistantID`.

#### Scenario: Message sent with snapshot
- **WHEN** `send(selectionSnapshot:)` called
- **THEN** snapshot stored against current assistant message ID

### Requirement: Snapshot routed to chat pipeline
Snapshot SHALL route through `CommandCenter.ask(text, preset, selectionSnapshot)`.

#### Scenario: ActionBar preset selected
- **WHEN** user clicks preset button on panel
- **THEN** CommandCenter.ask called with selection text, preset name, and snapshot

### Requirement: Snapshot available for insert-back
Snapshot SHALL be retrievable for insert-back operation on assistant response.

#### Scenario: Insert back requested
- **WHEN** user clicks Insert button on assistant message
- **THEN** snapshot retrieved by message ID for AX replacement
