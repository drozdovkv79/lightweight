## Purpose

The application uses a single fixed One Dark Pro palette everywhere, so users get a consistent muted dark appearance with no theme switching in settings or code.

## ADDED Requirements

### Requirement: Fixed One Dark Pro palette
The system SHALL render the entire interface in the One Dark Pro palette: background #282C34, primary text #ABB2BF, accents #C678DD, strings #98C379. No theme switching SHALL be offered.

#### Scenario: Single palette applied
- **WHEN** user opens any screen (chat, settings, input)
- **THEN** background is #282C34 and primary text is #ABB2BF

#### Scenario: No theme switching in settings
- **WHEN** user opens settings
- **THEN** no color theme picker is shown

#### Scenario: Accent and string colors in code
- **WHEN** a code block is syntax-highlighted
- **THEN** keywords use the purple accent and strings use the olive green

### Requirement: Saved theme preference ignored
The system SHALL ignore any previously saved `background_theme` preference and always use One Dark Pro.

#### Scenario: Legacy preference present
- **WHEN** the app launches with a stored `background_theme` value
- **THEN** the interface still renders in One Dark Pro
