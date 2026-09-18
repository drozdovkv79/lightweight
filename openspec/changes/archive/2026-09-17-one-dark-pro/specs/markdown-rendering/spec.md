## MODIFIED Requirements

### Requirement: Existing chat presentation is preserved
The system SHALL preserve text selection, the fixed One Dark Pro palette, code-block styling, message alignment, and the assistant stats line while rendering Markdown.

#### Scenario: Stats line unchanged in position
- **WHEN** an assistant message completes
- **THEN** the stats line still appears below the message bubble (in compact format per response-stats)

#### Scenario: Fixed palette and selection
- **WHEN** message text is displayed or selected
- **THEN** rendered Markdown uses the fixed One Dark Pro colors and remains selectable
