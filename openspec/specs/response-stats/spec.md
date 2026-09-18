# response-stats Specification

## Purpose

Отображение статистики ответа (токены, время) под каждым сообщением ассистента для мониторинга потребления ресурсов.

## Requirements

### Requirement: Usage data parsing from streaming response
The system SHALL parse `usage` field from the last streaming chunk of an OpenAI-compatible API response. The `usage` object contains `prompt_tokens`, `completion_tokens`, and `total_tokens` integer fields.

#### Scenario: Server returns usage in final chunk
- **WHEN** streaming response completes (last `data:` chunk before `data: [DONE]`)
- **THEN** system extracts `usage.prompt_tokens`, `usage.completion_tokens`, and `usage.total_tokens` from that chunk

#### Scenario: Server does not return usage
- **WHEN** streaming response completes without `usage` field in any chunk
- **THEN** system displays stats with token counts as "—" (unknown)

### Requirement: Response time measurement
The system SHALL measure elapsed wall-clock time from the moment the request is sent (`URLSession.shared.bytes`) to the moment `data: [DONE]` is received.

#### Scenario: Response time displayed
- **WHEN** assistant response completes
- **THEN** system records elapsed time in seconds with one decimal place

### Requirement: Stats display under assistant messages
The system SHALL display a stats line beneath each assistant message containing: model name, prompt tokens, completion tokens, total tokens, and response time.

#### Scenario: Stats visible for completed response
- **WHEN** assistant message is appended to chat
- **THEN** a single-line stats summary appears below the message bubble showing "model · prompt: N · completion: N · total: N · N.Ns"

#### Scenario: Stats not shown for user messages
- **WHEN** a user message is displayed
- **THEN** no stats line is shown beneath it

### Requirement: Stats model on ChatMessage
The system SHALL extend the ChatMessage model to carry optional stats metadata (usage tokens, response time, model name) that are populated only for assistant messages.

#### Scenario: Assistant message has stats
- **WHEN** assistant response completes with usage data
- **THEN** ChatMessage stores promptTokens, completionTokens, totalTokens, responseTime, and model

#### Scenario: User message has no stats
- **WHEN** user sends a message
- **THEN** ChatMessage stats fields are nil
