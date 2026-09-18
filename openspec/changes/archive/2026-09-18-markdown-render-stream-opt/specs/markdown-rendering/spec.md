## MODIFIED Requirements

### Requirement: Parsed markdown is cached per message
The system SHALL cache parsed Markdown blocks (`Markdown.Document` result) per assistant message id, and SHALL not re-parse the same content in `ContentView.body` or `MessageRow.body`.

#### Scenario: Cache prevents re-parse
- **WHEN** `ContentView` updates due to `streamingContent` change
- **THEN** `LazyVStack` messages do not invoke `Markdown.Document(parsing:)` again
