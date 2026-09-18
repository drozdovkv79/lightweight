## 1. Diagnostics

- [x] 1.1 `SelectionLog` enum: os_log + NSLog, единые точки логирования (SelectionAssistant/SelectionLog.swift)
- [x] 1.2 Вставить лог в цепочку: hotkey registered (+OSStatus, метод), tap fallback installed, monitor fired, AX trusted, selection read (len/nil), mode dispatch, notification posted/delivered

## 2. Hotkey reliability

- [x] 2.1 `installHotKey()`: читать комбинацию из `UserDefaults` ключа `selection_hotkey` (default `cmd-shift-space`); логировать OSStatus `RegisterEventHotKey`
- [x] 2.2 CGEvent tap fallback: при `RegisterEventHotKey != noErr` ставить listen-only keyDown tap (cmd+shift, без secondaryFn), reinstall через `stop()`/`start()`, дедуп с RegisterEventHotKey
- [x] 2.3 Settings: picker комбинации (`⌘⇧Space` / `⌃⌥⌘Space` / `⌥⇧Space`), смена → restart монитора
- [x] 2.4 App.swift:192 — текст permission-алерта берёт название текущего хоткея, не хардкод "Option+Shift+Space"

## 3. Selection read (Safari)

- [x] 3.1 `readSelection()`: fallback marker range — `kAXSelectedTextMarkerRangeAttribute` → `kAXStringForMarkerRangeParameterizedAttribute`
- [x] 3.2 Перед fallback: установить `kAXManualAccessibilityAttribute = true` на focused web area (идемпотентно)
- [x] 3.3 Логировать результат каждого шага fallback (D3 порядок: AXSelectedText → marker range → nil)

## 4. Default mode + delivery

- [x] 4.1 Дефолт `selection_mode` → `actionbar`: `UserDefaults.register(defaults:)` + убрать inline `"direct"` из Coordinator и SettingsView `@AppStorage`
- [x] 4.2 Перенести обработку `.selectionAssistantDirect` из `ContentView.onReceive` в `AppDelegate` (weak ChatViewModel от LightweightChatApp); при закрытом окне — send + activateMainWindow работают
- [x] 4.3 `scheduleAutomaticTrigger`: debounce из `autoInvokeDelay` (provider-замыкание вместо хардкода 0.3)

## 5. Verification

- [x] 5.1 `swift build` + `swift test` зелёные
- [ ] 5.2 GUI-чек: выделение в Safari → панель пресетов; выделение в Notes → панель; `⌘⇧Space` с выделением → срабатывает; закрыть окно → триггер в actionbar/direct работает; Settings-смена комбинации живая
- [ ] 5.3 Консоль: цепочка логов видна, тихих обрывов нет
