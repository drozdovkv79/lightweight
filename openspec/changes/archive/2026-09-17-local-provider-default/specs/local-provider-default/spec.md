## Purpose

Изменяет URL провайдера по умолчанию на локальный сервер `http://127.0.0.1:8000/v1/chat/completions` и загружает список LLM-моделей из локального кэша Hugging Face через `hf cache ls --json`.

## ADDED Requirements

### Requirement: Default provider URL is localhost
The system SHALL use `http://127.0.0.1:8000/v1/chat/completions` as the default API endpoint when `provider_url` is not set in `UserDefaults`.

#### Scenario: First launch with no provider_url set
- **WHEN** user launches app and no `provider_url` exists in `UserDefaults`
- **THEN** app uses `http://127.0.0.1:8000/v1/chat/completions` as endpoint

#### Scenario: User has custom provider_url set
- **WHEN** `provider_url` exists in `UserDefaults`
- **THEN** app uses the custom URL, not the default

### Requirement: Models loaded from local Hugging Face cache
The system SHALL execute `hf cache ls --json` to list locally cached models. Each model SHALL use `repo_id` field (without `model/` prefix) as the model identifier.

#### Scenario: Cached models exist
- **WHEN** user loads models
- **THEN** app runs `hf cache ls --json`, parses `repo_id` fields, strips `model/` prefix, appends `:nitro` suffix

#### Scenario: No cached models
- **WHEN** `hf cache ls` returns empty array
- **THEN** model list is empty, user sees "0 models loaded"

#### Scenario: `hf` CLI not found
- **WHEN** `hf` command is not available
- **THEN** app shows error, model list stays empty

## REMOVED Requirements

### Requirement: Models loaded from Hugging Face Hub via `hf models list`
**Reason**: Replaced by local cache loading via `hf cache ls`
**Migration**: `loadModelsFromHF()` now calls `hf cache ls --json` instead of `hf models list --format json`. `ModelLoader.parseHFModels()` updated to parse `repo_id` from cache format.

### Requirement: Default URL is OpenRouter
**Reason**: Replaced by localhost default
**Migration**: Default `provider_url` is now `http://127.0.0.1:8000/v1/chat/completions`. Existing users with empty `provider_url` will see the new default.
