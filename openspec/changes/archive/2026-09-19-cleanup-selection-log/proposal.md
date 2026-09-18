## Why

`SelectionLog` (добавлен в рамках `fix-selection-trigger-reliability` как диагностический инструмент) остаётся в коде. Он добавляет `Logger` + `NSLog` вызовы в каждый шаг цепочки триггера и в AppDelegate. Для продакшена это избыточный шум в unified logging (виден в Console, растёт в disk-usage) и не несёт функциональной ценности — цепочка работает корректно, диагностика больше не нужна.

## What Changes

- Удалить `SelectionAssistant/SelectionLog.swift`
- Убрать все вызовы `SelectionLog.log(...)` из:
  - `App.swift`
  - `SelectionAssistant/SelectionAssistantTriggerMonitor.swift`
  - `SelectionAssistant/SelectionAssistantCoordinator.swift`
  - `SelectionAssistant/SelectionAssistantPanel.swift`
- Убрать неиспользуемый импорт `import os` (если остался)
- Задача 1.1–1.2 из предыдущего change — удалена из tasks.md (предыдущий change уже архивирован, его задачи больше не актуальны)

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

(none — pure cleanup, no behavior change)

## Impact

- `LightweightChat/Sources/SelectionAssistant/SelectionLog.swift` — удалён
- `LightweightChat/Sources/App.swift`
- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantTriggerMonitor.swift`
- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantCoordinator.swift`
- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantPanel.swift`

Артефакты готовы для review. Когда готов — `/opsx-apply cleanup-selection-log`.
