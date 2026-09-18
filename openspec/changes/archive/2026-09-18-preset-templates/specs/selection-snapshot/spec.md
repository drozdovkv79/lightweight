## MODIFIED Requirements

### Requirement: Snapshot routed to chat pipeline
Snapshot SHALL route through `.selectionAssistantDirect` notification into `ChatViewModel.send(selectionSnapshot:template:)`. The user message SHALL be the preset template with `{{text}}` replaced by the selected text; if the template lacks the placeholder, selected text is appended after a blank line.

#### Scenario: ActionBar preset selected
- **WHEN** user clicks preset button on panel
- **THEN** notification carries snapshot and template; user message content is the expanded template and snapshot stored by assistant message ID

#### Scenario: Direct mode without template
- **WHEN** selection triggers in direct mode (no preset chosen)
- **THEN** selected text is sent as user message content unchanged
