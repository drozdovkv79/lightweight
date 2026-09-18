# provider-config Specification

## Purpose
Позволяет пользователю настроить URL AI-провайдера и загрузить список доступных LLM-моделей из локального Hugging Face Hub через `hf` CLI.

## Requirements

### Requirement: User can configure custom AI provider URL
The system SHALL allow the user to set a custom API endpoint URL via Settings GUI. The URL SHALL be persisted and used for all API requests instead of the hardcoded default.

#### Scenario: User sets custom provider URL
- **WHEN** user enters URL in Settings and closes the sheet
- **THEN** the URL is persisted and subsequent API requests use it

#### Scenario: User leaves URL empty
- **WHEN** user clears the URL field
- **THEN** app falls back to `https://openrouter.ai/api/v1/chat/completions`

#### Scenario: Server start switches provider URL
- **WHEN** a managed server is started from the toolbar
- **THEN** the provider URL is set to `http://127.0.0.1:8008/v1/chat/completions` and subsequent API requests use it

### Requirement: User can load AI models from local Hugging Face
The system SHALL execute `hf models list` via subprocess to populate the available model list. The model list SHALL be fetched dynamically on app launch or when the user requests refresh.

#### Scenario: User loads models from Hugging Face
- **WHEN** user opens Settings and triggers model load (or app launches)
- **THEN** app runs `hf models list --format json` and parses the output into a list of `LLMModel` objects

#### Scenario: `hf` CLI is not installed
- **WHEN** `hf` command is not found
- **THEN** app shows an error message and falls back to an empty model list with a prompt to install `hf`

#### Scenario: `hf` command fails
- **WHEN** `hf models list` exits with non-zero status
- **THEN** app shows error and falls back to last known model list or empty list

### Requirement: API key storage for custom providers
The system SHALL store the API key in macOS Keychain (`org.peterc.lightweight`) regardless of provider URL. The key SHALL be sent as `Authorization: Bearer <key>` header.

#### Scenario: User saves API key for custom provider
- **WHEN** user enters API key in Settings and saves
- **THEN** key is stored in Keychain and used for all subsequent requests
