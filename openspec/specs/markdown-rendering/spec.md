# markdown-rendering Specification

## Purpose

Assistant responses contain Markdown from the model, so the chat SHALL render complete Markdown structure instead of partial inline formatting.

## Requirements

### Requirement: Full Markdown structure in assistant messages
The system SHALL render assistant message content as structured Markdown, including paragraphs, headings, unordered and ordered lists, fenced code blocks, block quotes, inline code, emphasis, and links.

#### Scenario: Headings and paragraphs render as structure
- **WHEN** an assistant response contains headings and paragraphs
- **THEN** headings are visually distinct from body text and paragraphs keep their separation

#### Scenario: Lists render as lists
- **WHEN** an assistant response contains unordered or ordered lists
- **THEN** items appear as a list with markers or numbering, including nested items

#### Scenario: Fenced code blocks render as code
- **WHEN** an assistant response contains fenced code blocks
- **THEN** code appears in a distinct monospaced block, separate from prose

#### Scenario: Quotes and inline formatting render
- **WHEN** an assistant response contains block quotes, inline code, emphasis, or links
- **THEN** quotes are visually distinct, inline code is monospaced, emphasis is styled, and links are tappable

### Requirement: Existing chat presentation is preserved
The system SHALL preserve text selection, current theme colors, code-block styling, message alignment, and the assistant stats line while changing the Markdown renderer.

#### Scenario: Stats line unchanged
- **WHEN** an assistant message completes
- **THEN** the stats line still appears below the message bubble in its current format

#### Scenario: Theme and selection unchanged
- **WHEN** user changes background theme or selects message text
- **THEN** rendered Markdown follows theme colors and remains selectable

### Requirement: Invalid Markdown falls back to plain text
The system SHALL display message content as plain text when the content cannot be parsed as Markdown, without crashing or dropping the message.

#### Scenario: Malformed Markdown input
- **WHEN** an assistant response contains malformed Markdown
- **THEN** the full content is still shown as readable plain text

### Requirement: Prose uses proportional font, code uses monospace
The system SHALL render assistant message prose in a proportional sans-serif font at the chat font size, while code blocks and inline code use monospace. Theme foreground color is preserved.

#### Scenario: Prose and code fonts differ
- **WHEN** an assistant response contains prose and code
- **THEN** prose appears in sans-serif and code appears in monospace

### Requirement: Code block card with language, copy, and highlighting
The system SHALL render each fenced code block as a card with a header showing the language (or "code" when unspecified) and a Copy button. Copy places the raw code on the clipboard and confirms briefly. Code is syntax-highlighted; when highlighting fails the card falls back to plain monospace text.

#### Scenario: Copy code from card
- **WHEN** user clicks Copy on a code block
- **THEN** the raw code text is on the clipboard and the button shows confirmation

#### Scenario: Highlighting unavailable
- **WHEN** the language is unknown or highlighting fails
- **THEN** the card still shows the code as plain monospace text

### Requirement: Inline code pills
The system SHALL render inline code as a pill: monospace font on a subtle rounded background, inline within the paragraph flow.

#### Scenario: Inline code in paragraph
- **WHEN** a paragraph contains inline code
- **THEN** the code span appears as a distinct pill without breaking paragraph wrapping

### Requirement: Assistant message action row
The system SHALL show an action row beneath each assistant message with Copy (copies raw message Markdown), Like, and Dislike buttons. Like/Dislike are local visual toggles with no backend effect.

#### Scenario: Copy message
- **WHEN** user clicks Copy under an assistant message
- **THEN** the raw message text is on the clipboard

#### Scenario: Like toggle
- **WHEN** user clicks Like or Dislike
- **THEN** the button reflects the selected state; clicking again clears it

### Requirement: Tables render correctly
The system SHALL render markdown tables as bordered SwiftUI tables with a bold header row, regular-weight body rows, proportional column widths, and borders. Header SHALL use `.font(.system(size: fontSize).bold())` with a tinted background. Body cells SHALL use `.font(.system(size: fontSize))` without monospace, with `.overlay(Rectangle().stroke(...))` borders. All data SHALL be visible, including header cells parsed from `Markdown.Table.Head`.

#### Scenario: Table with header renders correctly
- **WHEN** a markdown table has a header row
- **THEN** the first row is bold with background tint, subsequent rows are normal weight with borders

#### Scenario: Table font matches prose
- **WHEN** a table renders
- **THEN** table cells use `.font(.system(size: fontSize))` without `.monospaced`

### Requirement: Parsed markdown is cached per message
The system SHALL cache parsed Markdown blocks (`Markdown.Document` result) per assistant message id, and SHALL not re-parse the same content in `ContentView.body` or `MessageRow.body`.

#### Scenario: Cache prevents re-parse
- **WHEN** `ContentView` updates due to `streamingContent` change
- **THEN** `LazyVStack` messages do not invoke `Markdown.Document(parsing:)` again
