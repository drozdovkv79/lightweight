# security-input-validation Specification

## Purpose
Не допустить краш/утечку от невалидного ввода/URL/AX.

## Requirements

### Requirement: Provider URL validated
System SHALL guard URL creation; bad URL SHALL fail gracefully, not crash.

#### Scenario: Bad URL
- **WHEN** user sets invalid provider_url
- **THEN** `send()` fails with message, no crash
