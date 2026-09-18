---
slug: selection-assistant
createdAt: 2026-09-18T00:00:00.000Z
---

## Why

Пользователь вынужден копировать выделенный текст → вставлять в чат → получать результат → вставлять обратно. Selection Assistant убирает этот цикл: выделил текст → горячая клавиша → AI обработала → результат вставлен обратно.

## What Changes

- **BREAKING**: Remove app sandbox — AX API требует не-sandboxed бандл с `com.apple.security.automation.apple-events` entitlement
- Добавить `SelectionAssistantCoordinator` — orchestrates trigger detection, AX reading, mode routing, snapshot storage
- Добавить глобальный горячий клавиша `Option+Shift+Space` для Invoke
- Добавить mouse-триггер: leftMouseUp с drag ≥3pt или double-click → debounced auto-invoke
- Добавить `SelectionAssistantPanel` — NSPanel с preset кнопками (Translate, Summarize, Custom), позиционируется возле selection rect
- Добавить настраиваемые пресеты в Settings (UserDefaults)
- Расширить `ChatViewModel`: `send(selectionSnapshot:)` — хранит snapshot по assistant message ID
- Добавить Insert Back кнопку на toolbar каждого assistant message — пишет AI result в оригинальный selection через AX API (`kAXSelectedTextAttribute`)
- Добавить Accessibility permission check + request flow (`AXIsProcessTrusted()`)
- Добавить debounce для auto-invoke (DispatchWorkItem)
- Добавить вне-клик dismiss для panel

## Capabilities

### New Capabilities
- `selection-trigger`: Глобальный горячий клавиш + mouse drag/double-click детекция, debounce, outside-click dismiss
- `selection-read`: AX API чтение выделенного текста из frontmost app, accessibility permission check
- `actionbar-overlay`: NSPanel с preset кнопками, позиционирование возле selection, настройка пресетов
- `selection-snapshot`: Снапшот selection → передача в ChatViewModel → привязка к assistant message
- `insert-back`: AX API запись AI результата обратно в оригинальный selection исходного приложения

### Modified Capabilities
- None

## Impact

- `LightweightChat/Sources/App.swift` — registration of global hotkey, mouse monitor, accessibility check
- `LightweightChat/Sources/ChatViewModel.swift` — `selectionSnapshotsByAssistantID`, `send(selectionSnapshot:)`, `insertSelection()`
- `LightweightChat/Sources/ContentView.swift` — Insert Back button on assistant message toolbar, panel dismiss handling
- `LightweightChat/Sources/SettingsView.swift` — preset configuration UI
- **NEW** `LightweightChat/Sources/SelectionAssistant/` — coordinator, panel, trigger monitor, snapshot model
- `LightweightChat/Resources/Info.plist` — entitlements (non-sandboxed, automation events)
- `LightweightChat/Package.swift` — no changes expected
