## Context

`AppDelegate` — обычный `NSObject`, не `@MainActor`. В `applicationDidFinishLaunching` добавлен `NotificationCenter`-обработчик `.selectionAssistantDirect`, который вызывает `chatVM.send(selectionSnapshot:template:)`. `ChatViewModel` — `ObservableObject`, метод `send(selectionSnapshot:template:)` помечен `@MainActor`. Swift-конкурентность предупреждает.

## Goals / Non-Goals

**Goals:**
- Убрать warning без изменения логики и без `@MainActor` на целом `AppDelegate` (там есть `GlobalActivationMonitor` + `activationMonitor.onActivate` без UI-обязательств).
- Минимальная правка: только обёртка вызова.

**Non-Goals:**
- Переписывать `AppDelegate` как actor.
- Изменять `ChatViewModel`.

## Decisions

**D1.** Обернуть вызов `chatVM.send` в `Task { @MainActor in { ... } }` вместо `@MainActor` на методе или делегате. Минимальный scope, не меняет архитектуру.

**D2.** `activateMainWindow()` после send остаётся вне `Task` — он не `@MainActor`-изолирован и не конкурентен.

## Risks / Trade-offs

- `Task { @MainActor in }` запускает асинхронно; send может выполниться чуть позже, чем при синхронном вызове. Для отправки в чат разница незаметна (отправка и тост не зависят от frame).
- Если `chatVM` deallocated между созданием Task и его выполнением — `weak` не нужен, `ChatViewModel` живёт дольше делегата.
