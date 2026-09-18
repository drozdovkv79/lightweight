## Why

OpenAI-compatible серверы возвращают `usage` (prompt_tokens, completion_tokens, total_tokens) в ответе. Сейчас эти данные игнорируются — пользователь не видит статистику по каждому ответу. Для отладки и мониторингаcost нужно знать сколько токенов потреблено.

## What Changes

- Добавить `usage` поле в `APIResponse` модель
- Парсить `usage` из последнего streaming chunk перед `[DONE]`
- Отображать статистику (prompt/completion tokens) под каждым ответом ассистента
- Добавить вычисление времени ответа (от отправки до `[DONE]`)

## Capabilities

### New Capabilities

- `response-stats`: Отображение статистики ответа (токены, время) под сообщениями ассистента

### Modified Capabilities

_(нет изменений существующих требований)_

## Impact

- `Models.swift`: расширить `APIResponse` + новая модель `ResponseUsage`
- `ChatViewModel.swift`: собирать `usage` и `responseTime`, передавать в `ChatMessage`
- `ContentView.swift`: отображать stats под `MessageBubble` для assistant сообщений
