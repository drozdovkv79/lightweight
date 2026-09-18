## MODIFIED Requirements

### Requirement: Table cells use fixed vertical size and cached text
The system SHALL render markdown table rows with `.fixedSize(horizontal: false, vertical: true)` so rows do not expand on re-render. Table cell text SHALL be derived from a cached array per table, not rebuilt from `Markdown.Table` in every `body` evaluation.

#### Scenario: Large table does not lag
- **WHEN** a message contains a markdown table with 10+ rows
- **THEN** `tableView` builds within 33ms and does not trigger full `LazyVStack` re-parse
