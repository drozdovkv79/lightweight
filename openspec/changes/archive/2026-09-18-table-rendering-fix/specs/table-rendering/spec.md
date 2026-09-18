## Purpose
Render markdown tables as bordered SwiftUI tables with bold header row, not as flat text.

## ADDED Requirements

### Requirement: Table renders with proper structure
The system SHALL parse Markdown.Table.Head for header cells and Markdown.Table.Body for data rows. The header SHALL be rendered bold with a background tint. Body cells SHALL have uniform column widths and borders.

#### Scenario: Table with header renders correctly
- WHEN a markdown table has a header row
- THEN the first row is bold with background, subsequent rows are normal weight with borders

#### Scenario: Table font matches regular text
- WHEN a table renders
- THEN table cells use the same font size as regular paragraph text (no monospace)
