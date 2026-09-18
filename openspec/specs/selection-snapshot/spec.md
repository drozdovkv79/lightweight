# selection-snapshot Specification

## Purpose
Снапшот контекста выделения передаётся в чат и привязывается к assistant сообщению.

## Requirements

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
Snapshot SHALL route through `.selectionAssistantDirect` notification into `ChatViewModel.send(selectionSnapshot:template:)`. The user message SHALL be the preset template with `{{text}}` replaced by the selected text; if the template lacks the placeholder, selected text is appended after a blank line.

#### Scenario: ActionBar preset selected
- **WHEN** user clicks preset button on panel
- **THEN** notification carries snapshot and template; user message content is the expanded template and snapshot stored by assistant message ID

#### Scenario: Direct mode without template
- **WHEN** selection triggers in direct mode (no preset chosen)
- **THEN** selected text is sent as user message content unchanged

### Requirement: Snapshot available for insert-back
Snapshot SHALL be retrievable for insert-back operation on assistant response.

#### Scenario: Insert back requested
- **WHEN** user clicks Insert button on assistant message
- **THEN** snapshot retrieved by message ID for AX replacement
