## Why

Build для production выдаёт warning `#ActorIsolatedCall`:
`AppDelegate` вызывает `chatVM.send(selectionSnapshot:template:)` в синхронном не-изолированном контексте. `send(selectionSnapshot:...)` помечен `@MainActor` — при `-warn-concurrency` (или `-strict-concurrency`) это станет ошибкой.

## What Changes

Обернуть вызов в `Task { @MainActor in }` в `AppDelegate`-обработчике `.selectionAssistantDirect` (App.swift:79).

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `actor-isolation`: `send(selectionSnapshot:template:)` вызывается из не-изолированного контекста через `Task { @MainActor in }`.

## Impact

- `LightweightChat/Sources/App.swift` — обработчик нотификации `.selectionAssistantDirect` в `AppDelegate`
- `LightweightChat/Sources/ChatViewModel.swift` — нет изменений (уже `@MainActor`)
