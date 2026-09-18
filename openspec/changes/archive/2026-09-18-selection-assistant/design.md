## Context

LightweightChat — macOS SwiftUI chat клиент для OpenRouter. Пользователи вынуждены вручную копировать выделенный текст, вставлять в чат, получать AI результат и вставлять обратно. Selection Assistant автоматизирует этот цикл: выделил текст → горячая клавиша → AI обработала → результат вставлен обратно.

## Goals

- Глобальный горячий клавиш `Option+Shift+Space` для Invoke selection assistant
- Авто-invoke при выделении текста мышью (drag ≥3pt, double-click) с debounce
- AX API чтение выделенного текста из любого приложения
- ActionBar Mode: NSPanel с preset кнопками (Translate, Summarize, Custom)
- Direct Mode: текст сразу в чат без UI
- Snapshot → Chat → Insert Back полная петля
- Настраиваемые пресеты в Settings
- Не-sandboxed app для AX API

## Non-Goals

- Нет голосовых команд
- Нет оффлайн-обработки (AI всегда через API)
- Нет поддержки нативных не-AX приложений (Safari, Electron — ограничено)
- Нет undo для insert-back операций

## Architecture

```
Trigger Layer          → SelectionAssistantTriggerMonitor
  • GlobalHotKey       → NSEvent.addLocalMonitorForEvents(.keyDown)
  • leftMouseUp drag   → NSEvent.addLocalMonitorForEvents(.leftMouseUp)
  • Double-click       → NSEvent.addLocalMonitorForEvents(.leftMouseDown) + clickCount check
         ↓
SelectionAssistantCoordinator
  • Check enabled (UserDefaults)
  • Check AX permission (AXIsProcessTrusted)
  • Read selection (AX API)
  • Validate not empty
  • Route to mode
         ↓
ActionBar Mode ───→ SelectionAssistantPanel (NSPanel near selection)
Direct Mode  ───→ ChatViewModel.send(selectionSnapshot:)
         ↓
Chat Pipeline
  • CommandCenter.ask(text, preset, snapshot)
  • Snapshot stored by assistant message ID
         ↓
Assistant Response
  • Insert button on toolbar (if snapshot exists)
  • AX write via kAXSelectedTextAttribute
```

## Key Design Decisions

1. **Не `.contextMenu`** — raw NSPanel только, как в документе. SwiftUI context menu не даёт нужной кастомизации.
2. **AX permission check before read** — запрос разрешения через системный диалог при первом триггере, если ещё не дано.
3. **Debounce через DispatchWorkItem** — cancel/reschedule pattern, как в документе. Не `Timer`, проще cancel.
4. **Snapshot по message ID** — связь snapshot↔message через `selectionSnapshotsByAssistantID: [UUID: SelectionSnapshot]`. Чистая связь, нет утечек.
5. **Insert Back через AX set** — `AXUIElementSetAttributeValue` с `kAXSelectedTextAttribute`. Один вызов, без сложной логики.
6. **Пресеты в UserDefaults** — массив строк. Settings UI редактирует. По умолчанию `["Translate", "Summarize"]`.
7. **Direct Mode — default** — нет UI, меньше friction. ActionBar — опциональный режим в настройках.
