## Purpose
Вызов `@MainActor`-изолированных методов из не-изолированного кода должен быть явно обёрнут в `Task { @MainActor in }`.

## ADDED Requirements

### Requirement: Actor-isolated call wrapping
Any call to a `@MainActor`-isolated method from a non-isolated context SHALL be wrapped in `Task { @MainActor in { ... } }` or the calling context SHALL be `@MainActor`.

#### Scenario: AppDelegate notification handler
- **WHEN** `AppDelegate` handles `.selectionAssistantDirect` notification
- **THEN** the call to `chatVM.send(selectionSnapshot:template:)` is dispatched inside `Task { @MainActor in }`
- **WHEN** build is invoked with `-strict-concurrency`
- **THEN** no `#ActorIsolatedCall` warning is emitted
