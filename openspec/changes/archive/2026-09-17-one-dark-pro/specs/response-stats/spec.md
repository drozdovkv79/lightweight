## MODIFIED Requirements

### Requirement: Stats display under assistant messages
The system SHALL display a compact stats line beneath each assistant message showing: input tokens as `↑N`, output tokens as `↓M`, generation speed as `X.X tok/s` (output tokens divided by response time), and response time as `Y.Ys`. Model name and total tokens SHALL NOT be shown. Missing values SHALL display as `—`.

#### Scenario: Stats visible for completed response
- **WHEN** assistant message is appended to chat
- **THEN** a single-line stats summary appears below the message bubble showing "↑N ↓M · X.X tok/s · Y.Ys"

#### Scenario: Stats not shown for user messages
- **WHEN** a user message is displayed
- **THEN** no stats line is shown beneath it

#### Scenario: Usage data missing
- **WHEN** the server returns no usage data
- **THEN** token fields and speed display as "—" while response time still shows
