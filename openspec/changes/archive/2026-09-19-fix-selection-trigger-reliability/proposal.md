## Why

Selection Assistant не работает у пользователя в двух местах:

1. **Хоткей `⌘⇧Space` мёртв.** После замены модификаторов с `Option+Shift` на `Cmd+Shift` (SelectionAssistantTriggerMonitor.swift:72) нажатие не даёт ничего. При этом `⌃⌥⌘Space` работает — но это другой механизм (`GlobalActivationMonitor`, CGEvent tap). Причина: `RegisterEventHotKey` возвращает `OSStatus`, который код игнорирует — при конфликте комбинации (системный шорткат, Raycast/Alfred, input source tool) регистрация молча падает. Плюс текст permission-алерта в App.swift:192 до сих пор говорит "press Option+Shift+Space" — устаревший.

2. **Панель пресетов не появляется при выделении текста** ни в Safari, ни в Notes. Три причины:
   - `selection_mode` по умолчанию `"direct"` (SettingsView:8, Coordinator:19) — в direct-режиме панель по спеке не показывается вообще, текст уходит в чат сразу. Пользователь ожидает actionbar.
   - Safari/WebKit не отдаёт `kAXSelectedTextAttribute` на web-контенте — `readSelection()` возвращает nil, цепочка молча обрывается. Спека `selection-read` даже кодифицирует это как "returns nil gracefully". Правильный путь — marker range API (`kAXSelectedTextMarkerRangeAttribute` + `kAXStringForMarkerRangeParameterizedAttribute`).
   - Обработка `.selectionAssistantDirect` висит на `ContentView.onReceive` (App.swift:175) — если главное окно закрыто, подписчика нет и нотификация теряется.

Дополнительно: `scheduleAutomaticTrigger` хардкодит `delay = 0.3`, игнорируя настройку `auto_invoke_delay` (нарушение спеки selection-trigger "configurable delay").

## What Changes

- Хоткей: проверка `OSStatus` от `RegisterEventHotKey` + fallback на CGEvent tap (тот же механизм, что у работающего `GlobalActivationMonitor`, AX уже выдана) + diagnostics-логирование всей цепочки триггера + обновление устаревшего текста алерта + hotkey делается настраиваемым в Settings.
- Чтение выделения: fallback на marker range API для Safari/WebKit, чтобы выделение в браузере тоже читалось.
- Режим по умолчанию: `selection_mode` меняется с `direct` на `actionbar` — панель пресетов появляется при выделении, как ожидает пользователь.
- Надёжность доставки: обработка `.selectionAssistantDirect` переносится из window-scoped `ContentView` в `AppDelegate` (работает при закрытом окне).
- Debounce: `scheduleAutomaticTrigger` использует `autoInvokeDelay` из настроек вместо хардкода.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `selection-trigger`: hotkey регистрация с проверкой OSStatus + CGEvent tap fallback; настраиваемая комбинация; debounce delay из настроек; диагностика цепочки.
- `selection-read`: Safari/WebKit чтение через marker range вместо "returns nil gracefully".
- `actionbar-overlay`: режим по умолчанию — actionbar; панель работает при закрытом главном окне.

## Impact

- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantTriggerMonitor.swift` — hotkey регистрация, fallback, debounce delay
- `LightweightChat/Sources/SelectionAssistant/SelectionAssistantCoordinator.swift` — readSelection marker range, default mode
- `LightweightChat/Sources/App.swift` — перенос notification handling, текст алерта
- `LightweightChat/Sources/SettingsView.swift` — default mode, hotkey настройка
- `openspec/specs/selection-trigger/spec.md`, `openspec/specs/selection-read/spec.md`, `openspec/specs/actionbar-overlay/spec.md` — после синка
