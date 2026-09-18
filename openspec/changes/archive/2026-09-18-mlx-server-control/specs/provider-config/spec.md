## MODIFIED Requirements

### Requirement: User can configure custom AI provider URL
The system SHALL allow the user to set a custom API endpoint URL via Settings GUI. The URL SHALL be persisted and used for all API requests instead of the hardcoded default. The system SHALL also set the URL automatically to the local server when a managed server is started from the toolbar.

#### Scenario: User sets custom provider URL
- **WHEN** user enters URL in Settings and closes the sheet
- **THEN** the URL is persisted and subsequent API requests use it

#### Scenario: User leaves URL empty
- **WHEN** user clears the URL field
- **THEN** app falls back to `https://openrouter.ai/api/v1/chat/completions`

#### Scenario: Server start switches provider URL
- **WHEN** a managed server is started from the toolbar
- **THEN** the provider URL is set to `http://127.0.0.1:8008/v1/chat/completions` and subsequent API requests use it
