## Context

Цепочка триггера сегодня: `SelectionAssistantTriggerMonitor` (Carbon `RegisterEventHotKey` + NSEvent global mouse monitors) → `SelectionAssistantCoordinator.trigger()` → `handleTrigger()` → `readSelection()` (только `kAXSelectedTextAttribute`) → dispatch по `selectionMode` → `.selectionAssistantDirect` нотификация → подписка в `ContentView.onReceive`.

Установленные факты:
- `RegisterEventHotKey` OSStatus игнорируется (SelectionAssistantTriggerMonitor.swift:70-77) — конфликт комбинации молча теряется.
- `GlobalActivationMonitor` (`⌃⌥⌘Space`) работает через CGEvent tap (`.listenOnly`, headInsert) и требует Accessibility — у пользователя она выдана (раз этот хоткей работает).
- `readSelection()` (Coordinator:125-136) читает только `kAXSelectedTextAttribute` на focused element — Safari/WebKit web-контент его не отдаёт.
- `selection_mode` default `"direct"` (SettingsView:8, Coordinator:19) — панель по спеке не показывается.
- Обработка `.selectionAssistantDirect` висит на `ContentView.onReceive` (App.swift:175-180) — окно закрыто → подписки нет → событие потеряно.
- `scheduleAutomaticTrigger` хардкодит `delay = 0.3` (TriggerMonitor:122), игнорируя `autoInvokeDelay`.
- Текст permission-алерта (App.swift:192) упоминает старый `Option+Shift+Space`.

## Goals / Non-Goals

**Goals:**
- Хоткей срабатывает гарантированно: проверка OSStatus + CGEvent tap fallback + настраиваемая комбинация.
- Выделение в Safari читается через marker range fallback.
- Панель пресетов появляется по умолчанию (actionbar default).
- События триггера не теряются при закрытом главном окне.
- Диагностический лог по всей цепочке — «не работает» локализуется за минуту.

**Non-Goals:**
- Реакция на отпускание клавиш (keyUp) и consume событий (tap остаётся listen-only).
- Поддержка выделения в приложениях без AX вообще.
- Изменение пайплайна отправки в чат после dispatch.

## Decisions

**D1. Hotkey: двухслойная схема.** `RegisterEventHotKey` остаётся основным (без AX), но: (а) логируем OSStatus, (б) при неуспехе ставим CGEvent tap (`.listenOnly`, `keyDown`, фильтр `cmdKey|shiftKey` + Space, без `.maskSecondaryFn`) — тот же паттерн, что в `GlobalActivationMonitor`, AX уже нужна для чтения селекшена. Tap НЕ consume-ит событие. Альтернатива «только tap» отклонена: без AX хоткей бы умер совсем, а RegisterEventHotKey работает бесплатно.

**D2. Комбинация хоткея — из Settings.** `UserDefaults` ключ `selection_hotkey` (значение `"cmd-shift-space"`), UI в SettingsView. Дефолт `cmd-shift-space`. Регистрация в `installHotKey()` читает ключ; смена в Settings → `stop()` + `start()`.

**D3. Marker range fallback в readSelection.** Порядок: (1) `kAXSelectedTextAttribute` на focused element; (2) если nil/пусто — `kAXFocusedUIElementAttribute` → `kAXSelectedTextMarkerRangeAttribute` → `AXUIElementCopyParameterizedAttributeValue(kAXStringForMarkerRangeParameterizedAttribute)`; (3) nil. Всё внутри `readSelection()`, сигнатура не меняется.

**D4. Default mode → actionbar.** Меняем дефолт в Coordinator (`selectionMode` getter: nil → `.actionbar`) и в SettingsView `@AppStorage`. Существующие юзеры с явно сохранённым `"direct"` остаются на direct — меняем только дефолт для свежих/не настроенных. Внимание: у пользователя уже записан `direct` (SettingsView `@AppStorage` с default `direct` писал значение при открытии Settings) — поэтому в тасках отдельный шаг: миграция — если ключ не менялся пользователем осознанно, трактуем отсутствие ключа как actionbar; `@AppStorage` с registered default через `UserDefaults.register(defaults:)` вместо inline default.

**D5. Notification handling → AppDelegate.** `AppDelegate` получает `.selectionAssistantDirect`, держит weak-ссылку на `ChatViewModel` (передаётся из `LightweightChatApp` через `init`/метод) и вызывает `chatVM.send` + `activateMainWindow`. `ContentView.onReceive` убираем. Алерт permission остаётся во view (UI-объект), но при закрытом окне показывать нечего — логируем.

**D6. Диагностика.** Единая точка `SelectionLog` (enum с os_log + NSLog fallback): `log(_ step: String, _ detail: String)`. Точки: hotkey registered (method + OSStatus), tap fallback installed, monitor fired, AX trusted?, selection read (len / nil reason), mode dispatch, notification posted/delivered.

**D7. Debounce из настроек.** `scheduleAutomaticTrigger` читает `auto_invoke_delay` (Coordinator уже имеет computed `autoInvokeDelay`; передаём через замыкание-провайдер в TriggerMonitor, чтобы не тянуть зависимость).

## Risks / Trade-offs

- CGEvent tap fallback с `.listenOnly` не потребляет событие: если комбинацию держит другой процесс-владелец, событие всё равно уйдёт ему — приемлемо, фиксируем в логе.
- Marker range API в некоторых WebKit-версиях требует AXManualAccessibility на AXWebArea — добавляем установку `kAXManualAccessibilityAttribute = true` перед fallback (безопасно, идемпотентно).
- Миграция дефолта mode (D4): `UserDefaults.register(defaults:)` не перезаписывает сохранённые значения; если у пользователя уже записан `direct` от прошлых запусков, дефолт не сработает. Решение — registered default + разовая миграция по ключу-версии `selection_mode_migrated_v1`, если значение совпадает со старым дефолтом и пользователь его не менял (проверить через `object(forKey:)` до первого обращения). Упрощение допустимо: просто registered default, а пользователю сказать сменить в Settings, если не сработало.
- Двойной триггер (RegisterEventHotKey + tap оба живы) исключается: tap ставится только при неуспехе регистрации.
