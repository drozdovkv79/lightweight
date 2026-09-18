## MODIFIED Requirements

### Requirement: Tables render correctly
The system SHALL render markdown tables as bordered SwiftUI tables with a bold header row, regular-weight body rows, proportional column widths, and borders. Header SHALL use `.font(.system(size: fontSize).bold())` with a tinted background. Body cells SHALL use `.font(.system(size: fontSize))` without monospace, with `.overlay(Rectangle().stroke(...))` borders. All data SHALL be visible, including header cells parsed from `Markdown.Table.Head`.
